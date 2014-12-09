require 'sinatra'
require 'omniauth'
require 'omniauth-google-oauth2'

class Flash < Sinatra::Application

  get '/' do
    "Hello from Flash development!"
  end


  # User Authentication
  enable :sessions
  use OmniAuth::Builder do
    provider :google_oauth2, '974621706491-tsqu6igv0ipj5gr4tb7sd38cpjmstrnd.apps.googleusercontent.com', 'qjF9FuDdloHSWSRnEYw6gWSE'
  end

  get '/login' do
    "this is the page for logging in"
  end

  get '/auth/google_oauth2/callback' do
    binding.pry
  end


  # Development
  configure :development do
    require 'pry'
  end

end
