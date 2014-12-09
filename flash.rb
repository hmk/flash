require 'sinatra'
require 'omniauth'
require 'omniauth-google-oauth2'
require 'ohm'
require 'redis'
require 'haml'

class Cache
  def self.set key, value
    Ohm.redis.call("SET", key.to_s, value.to_s)
  end

  def self.get key
    Ohm.redis.call("GET", key.to_s)
  end
end


class Flash < Sinatra::Application

  get '/' do
    client_id = Ohm.redis.call("GET", "google_client_id")
    client_secret = Ohm.redis.call("GET", "google_client_secret")
    haml :config_form, locals: { client_id: client_id, client_secret: client_secret}
  end

  post '/config' do
    Cache.set(:google_client_id, params[:google_client_id])
    Cache.set(:google_client_secret, params[:google_client_secret])
    redirect to '/'
  end

  # User Authentication
  enable :sessions
  use OmniAuth::Builder do
    provider :google_oauth2, setup: ->(env) do
      env['omniauth.strategy'].options.client_id = Cache.get(:google_client_id)
      env['omniauth.strategy'].options.client_secret = Cache.get(:google_client_secret)
    end
  end

  get '/login' do
    "this is the page for logging in"
  end

  get '/auth/google_oauth2/callback' do
    content_type 'text/plain'
    request.env['omniauth.auth'].to_hash.inspect rescue "No Data"
  end

  get '/auth/failure' do
    content_type 'text/plain'
    request.env['omniauth.auth'].to_hash.inspect rescue "No Data"
  end


  # Development
  configure :development do
    require 'pry'
  end

end
