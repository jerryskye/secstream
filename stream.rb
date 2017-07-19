require 'sequel'
require 'twitter'
require 'yaml'

config = YAML.load_file 'config.yml'
DB = Sequel.connect(config)

client = Twitter::Streaming::Client.new do |conf|
  conf.consumer_key = config[:consumer_key]
  conf.consumer_secret = config[:consumer_secret]
  conf.access_token = config[:access_token]
  conf.access_token_secret = config[:access_token_secret]
end

client.filter(config[:filter]) do |tweet|
  begin
    case tweet
    when Twitter::Tweet
      unless tweet.retweet?
        tw = {id: tweet.id, text: tweet.full_text, author: tweet.user.screen_name, created_at: tweet.created_at, hashtags: tweet.hashtags?? tweet.hashtags.map(&:text).join(",") : nil}
        DB[:tweets].insert(tw)
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
