require 'sinatra'
require 'omniauth'
require 'omniauth-google-oauth2'
require 'ohm'
require 'haml'

class DynamicOmniauth
  # OmniAuth expects the class passed to setup to respond to the #call method.
  # env - Rack environment
  def self.call(env)
    new(env).setup
  end

  # Assign variables and create a request object for use later.
  # env - Rack environment
  def initialize(env)
    @env = env
  end

  # The main purpose of this method is to set the consumer key and secret.
  def setup
    @env['omniauth.strategy'].options.merge!(custom_credentials)
  end

  # Use the subdomain in the request to find the account with credentials
  def custom_credentials
    {
      client_id: Ohm.redis.call("GET", "google_client_id"),
      client_secret: Ohm.redis.call("GET", "google_client_secret")
    }
  end
end

class Flash < Sinatra::Application

  get '/' do
    client_id = Ohm.redis.call("GET", "google_client_id")
    client_secret = Ohm.redis.call("GET", "google_client_secret")
    haml :config_form, locals: { client_id: client_id, client_secret: client_secret}
  end

  post '/config' do
    Ohm.redis.call("SET", "google_client_id", params[:google_client_id])
    Ohm.redis.call("SET", "google_client_secret", params[:google_client_secret])
    redirect to '/'
  end

  # Sandbox (todelete)
  get '/test' do
    "<p>id: `#{Ohm.redis.call("GET", "google_client_id")}`</p><p>`#{Ohm.redis.call("GET", "google_client_secret")}`</p>"
  end

  # User Authentication
  enable :sessions
  use OmniAuth::Builder do
    provider :google_oauth2, setup: DynamicOmniauth
  end

  get '/login' do
    "this is the page for logging in"
  end

  get '/auth/google_oauth2/callback' do
    env["omniauth.auth"].info.email
  end

  # cache of


  # Development
  configure :development do
    require 'pry'
  end

end
