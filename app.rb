require 'roda'
require 'sequel'
require 'yaml'

class App < Roda
  plugin :public
  plugin :render, engine: 'haml'

  opts.merge!(YAML.load_file('config.yml'))
  DB = Sequel.connect(opts[:db])

  def url str
    opts[:base_url] + str
  end

  route do |r|
    r.root do
      @tweets = DB[:tweets].order(Sequel.desc(:created_at))
      view :tweets
    end

    r.get 'with_hashtags' do
      @tweets_with_hashtags = DB[:hashtags].join(:hashtags_tweets, :hashtag_id => :id)
        .join(:tweets, :id => :tweet_id)
        .select(:author, :text, :created_at, Sequel::SQL::Function.new(:group_concat, :hashtag).as(:hashtags))
        .order(Sequel.desc(:created_at))
        .group(:tweet_id)
      view :hashtags
    end

    r.get 'stats' do
      @hashtags = DB[:hashtags].join(:hashtags_tweets, :hashtag_id => :id)
        .join(:tweets, :id => :tweet_id)
        .group_and_count(:hashtag_id)
        .select_append(:hashtag, Sequel::SQL::Function.new(:min, :created_at).as(:first_observed), Sequel::SQL::Function.new(:max, :created_at).as(:last_observed))
      view :stats
    end

    r.public
  end
end
