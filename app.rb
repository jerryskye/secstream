require 'roda'
require 'sequel'
require 'yaml'

class App < Roda
  plugin :public
  plugin :render, engine: 'haml'

  DB = Sequel.connect(YAML.load_file('config.yml')[:db])

  route do |r|
    r.root do
      @tweets = DB[:tweets]
      view :index
    end

    r.public
  end
end
