require 'rake'
require 'sequel'
require 'yaml'
require 'pry'

task :default => :tinker
config = YAML.load_file('config.yml')

task :tinker do
  DB = Sequel.connect(config)
  pry
end

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    Sequel.extension :migration
    db = Sequel.connect(config)
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, "migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "migrations")
    end
  end
end
