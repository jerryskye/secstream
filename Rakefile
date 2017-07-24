require 'rake'
require 'sequel'
require 'yaml'

task :default => :tinker
config = YAML.load_file('config.yml')
DB = Sequel.connect(config[:db])

desc "Play with the app"
task :tinker do
  require 'pry'
  require 'sidekiq'
  require_relative 'stream'
  pry
end

desc "Populate the users table"
task :update_users => 'db:migrate' do
  puts "Populating the users table"
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

desc "Start the user stream"
task :user_stream => :update_users do
  require 'sidekiq'
  require_relative 'stream'
  puts 'Starting the user stream'
  jid = Sidekiq.redis {|r| r.get('user_stream_jid')}
  StreamWorker.cancel!(jid) unless jid.nil?
  jid = StreamWorker.perform_async(follow: DB[:users].map(:id).join(','))
  Sidekiq.redis {|r| r. set('user_stream_jid', jid)}
end

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    Sequel.extension :migration
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(DB, "migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(DB, "migrations")
    end
  end
end
