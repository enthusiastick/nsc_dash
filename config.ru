require 'dashing'
require 'dotenv'
require 'haml'
require 'json'
require 'omniauth/strategies/google_oauth2'
require 'pry'

Dotenv.load

configure do

  set :auth_token, ENV['AUTH_TOKEN']
  set :default_dashboard, 'select'

  helpers do
    def protected!
      redirect '/auth/google_oauth2' unless session[:authorized]
    end
  end

  use Rack::Session::Cookie, secret: ENV['SECRET_KEY_BASE']

  use OmniAuth::Builder do
    provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET']
  end

  get '/auth/google_oauth2/callback' do
    if auth = request.env['omniauth.auth']
      if request.env['omniauth.auth']['info']['email'].split("@").last == "maidpro.com"
        session[:authorized] = true
        redirect '/select'
      else
        redirect 'auth/failure'
      end
    else
      redirect '/auth/failure'
    end
  end

  get '/auth/failure' do
    'Nope.'
  end

end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
