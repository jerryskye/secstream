require 'sequel'
require 'twitter'
require 'yaml'

config = YAML.load_file 'config.yml'
DB = Sequel.connect(config[:db])
users = DB[:users]

client = Twitter::Streaming::Client.new(config[:client])

client.filter(follow: users.map(:id).join(",")) do |tweet|
  begin
    case tweet
    when Twitter::Tweet
      user = users.where(id: tweet.user.id).first
      unless user.nil?
        tw = {id: tweet.id, text: tweet.full_text, author: user[:screen_name], created_at: tweet.created_at, hashtags: tweet.hashtags?? tweet.hashtags.map(&:text).join(",") : nil}
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
