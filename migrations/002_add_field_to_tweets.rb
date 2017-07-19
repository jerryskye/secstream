Sequel.migration do
  up do
    alter_table :tweets do
      add_column :hashtags, String, :null => true
    end
  end

  down do
    alter_table :tweets do
      drop_column :hashtags
    end
  end
end
