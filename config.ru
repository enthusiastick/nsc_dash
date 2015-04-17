require 'dashing'
require 'dotenv'
require 'haml'
require 'json'
require 'pry'

Dotenv.load

configure do
  set :auth_token, ENV['AUTH_TOKEN']
  set :default_dashboard, 'select'

  helpers do
    def protected!
      # auth goes here
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
