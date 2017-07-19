require 'sequel'
require 'twitter'
require 'yaml'

config = YAML.load_file 'config.yml'
DB = Sequel.connect(config[:db])

client = Twitter::Streaming::Client.new(config[:client])

client.filter(follow: DB[:users].map(:id).join(",")) do |tweet|
  begin
    case tweet
    when Twitter::Tweet
      user = DB[:users].where(id: tweet.user.id).first
      unless user.nil?
        tw = {id: tweet.id, text: tweet.full_text, author: user[:screen_name], created_at: tweet.created_at}
        DB[:tweets].insert(tw)
        if tweet.hashtags?
          tweet.hashtags.each do |hashtag|
            hashtag_id = DB[:hashtags].select(:id).where(hashtag: hashtag.text).get(:id) || DB[:hashtags].insert(hashtag: hashtag.text)
            DB[:hashtags_tweets].insert(hashtag_id: hashtag_id, tweet_id: tweet.id)
          end
        end
        puts "#{tw[:author]} just tweeted"
        STDOUT.flush
      end
    end
  rescue => e
    case e
    when Sequel::UniqueConstraintViolation, Sequel::DatabaseError
      #do nothing
    else
      puts "#{e.class} while processing #{tweet.id}: #{e}"
      puts e.backtrace
      STDOUT.flush
    end
  end
end
