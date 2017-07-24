require 'roda'
require 'sequel'
require 'yaml'
require 'twitter'
require 'sidekiq'
require_relative 'stream'

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
        .order(Sequel.desc(:last_observed))
      view :stats
    end

    r.get 'choose_hashtags' do
      @hashtags = DB[:hashtags].order(Sequel.desc(:id))
      view :choose_hashtags
    end

    r.post 'choose_hashtags' do
      hashtags = DB[:hashtags].where(id: r['hashtags'].keys.map(&:to_i)).map(:hashtag).join(',')
      StreamWorker.perform_async(track: hashtags)
    end

    r.public
  end
end
