require 'sequel'
require 'twitter'
require 'yaml'
require 'sidekiq'

class StreamWorker
  include Sidekiq::Worker

  CONFIG = YAML.load_file 'config.yml'
  DB = Sequel.connect(CONFIG[:db])

  def perform(args)
    return if cancelled?
    client = Twitter::Streaming::Client.new(CONFIG[:client])
    check_for_user = args.has_key? 'follow'
    puts args
    client.filter(args) do |tweet|
      begin
        if tweet.is_a? Twitter::Tweet
          next if DB[:users].where(id: tweet.user.id).first.nil? and check_for_user
          tw = {id: tweet.id, text: tweet.full_text, author: tweet.user.screen_name, created_at: tweet.created_at, url: tweet.uri.to_s}
          DB[:tweets].insert(tw)
          if tweet.hashtags?
            tweet.hashtags.each do |hashtag|
              hashtag_id = DB[:hashtags].select(:id).where(hashtag: hashtag.text).get(:id) || DB[:hashtags].insert(hashtag: hashtag.text)
              DB[:hashtags_tweets].insert(hashtag_id: hashtag_id, tweet_id: tweet.id)
            end
          end
        end
      rescue => e
        puts "#{e.class} while processing #{tweet.id}: #{e}"
        puts e.backtrace
      ensure
        return if cancelled?
      end
    end
  end

  def cancelled?
    Sidekiq.redis {|c| c.exists("cancelled-#{jid}")}
  end

  def self.cancel!(jid)
    Sidekiq.redis {|c| c.setex("cancelled-#{jid}", 86400, 1)}
  end
end
