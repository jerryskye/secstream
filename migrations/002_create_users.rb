Sequel.migration do
  up do
    create_table :users do
      Bignum :id, :unique => true, :primary_key => true, :null => false, :index => true
      String :screen_name
    end
  end

  down do
    drop_table :users
  end
end
