Sequel.migration do
  up do
    create_table :hashtags do
      primary_key :id
      String :hashtag
    end
  end

  down do
    drop_table :hashtags
  end
end
