Sequel.migration do
  up do
    alter_table :tweets do
      add_column :url, String
    end
  end

  down do
    alter_table :tweets do
      drop_column :url
    end
  end
end
