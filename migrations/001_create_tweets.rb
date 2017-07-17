Sequel.migration do
  up do
    create_table :tweets do
      String :id, :unique => true, :primary_key => true, :null => false
      Time :created_at
      String :text
      String :author
    end
  end

  down do
    drop_table :tweets
  end
end
