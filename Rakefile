require 'rake'
require 'sequel'
require 'yaml'

task :default => :tinker
config = YAML.load_file('config.yml')

desc "Play with the DB"
task :tinker do
  DB = Sequel.connect(config[:db])
  require 'pry'
  pry
end

desc "Populate the users table"
task :update_users => 'db:migrate' do
  puts "Populating the users table"
  DB = Sequel.connect(config[:db])
  users = YAML.load_file 'users.yml'
  require 'twitter'
  client = Twitter::REST::Client.new(config[:client])
  users_dataset = DB[:users]
  users_dataset.exclude(screen_name: users).delete
  require 'ruby-progressbar'
  progressbar = ProgressBar.create(:total => users.count,
                                   :format => '%t: %c/%C |%B|')
  users.each do |screen_name|
    unless users_dataset.where(screen_name: screen_name).count > 0
      user_id = client.user(screen_name).id
      users_dataset.insert(id: user_id, screen_name: screen_name)
    end
    progressbar.increment
  end
end

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    Sequel.extension :migration
    db = Sequel.connect(config[:db])
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, "migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "migrations")
    end
  end
end
