Sequel.migration do
  up do

    create_table(:hashtags_tweets) do
      foreign_key :hashtag_id, :hashtags, :null=>false
      foreign_key :tweet_id, :tweets, :null=>false, :type => 'bigint'
      primary_key [:hashtag_id, :tweet_id]
      index [:hashtag_id, :tweet_id]
    end
  end

  down do
    drop_table :hashtags_tweets
  end
end
