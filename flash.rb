require 'rubygems'
require 'bundler'
Bundler.require(:default, :assets, ENV["RACK_ENV"] || 'development')

# Configure Ohm
Ohm.redis = Redic.new(ENV["REDISTOGO_URL"]) if production?

class Cache
  def self.set key, value
    Ohm.redis.call("SET", key.to_s, value.to_s)
  end

  def self.get key
    Ohm.redis.call("GET", key.to_s)
  end
end

class Command < Ohm::Model
  attribute :name
  attribute :description
  attribute :url
  attribute :example

  unique :name
  index :name
end

class Flash < Sinatra::Application

  get '/' do
    # redirect to config if the config vars are not set (this should only happen once)
    required_config_vars = [:google_client_id,:google_client_secret, :company_name, :regex_matcher, :url, :app_name, :admin_users]
    required_config_vars.each do |config_var_name|
      if Cache.get(config_var_name).nil?
        redirect to '/config'
      end
    end
    # force login if user is not logged in
    redirect to('/login') unless logged_in?
    redirect to('/unauthorized') unless logged_in_and_matches_regex?
    haml :main
  end

  # Search
  get '/search' do
    return haml :search unless params[:q]
    begin
      command_name, *args = params[:q].split(/\s+/)
      command = Command.find(name: command_name).first
      if !command
        return "no command found with that name `#{command_name}`"
      end
      redirect_url = command.url % args.to_a.join('%20')
      redirect redirect_url, 303
    rescue
      return "error parsing your query: `#{params[:q]}`"
    end
  end

  # Commands
  namespace '/commands' do
    # List Commands
    get do
      haml :'commands/index', locals: { commands: Command.all }
    end

    get '/:id/edit' do
      command_id = params[:id]
      command = Command[command_id]
      haml :'commands/form', locals: { command: command }
    end

    # Form for new Command
    get '/new' do
      haml :'commands/new', locals: { command: Command.new }
    end

    # Create a new Command
    post do
      attributes = { name: params[:name], url: params[:url], description: params[:description], example: params[:example] }
      # old command
      if params[:id]
        command = Command[params[:id]]
        if command.update(attributes)
          redirect to('/#commands')
        else
          "there was an error updating your command"
        end
      end

      # new command
      command = Command.new(attributes)
      if command.save
        redirect to('/commands')
      else
        "there was an error saving your command"
      end
    end
  end

  # Onboarding / Config
  get '/config' do
    return haml :admin_required if Cache.get(:admin_users) &&
      !is_admin_user?
    client_id = Cache.get(:google_client_id)
    client_secret = Cache.get(:google_client_secret)
    company_name = Cache.get(:company_name)
    regex_matcher = Cache.get(:regex_matcher)
    admin_users = Cache.get(:admin_users)
    url = Cache.get(:url)
    app_name = Cache.get(:app_name)
    haml :config_form, locals: {
      client_id: client_id,
      client_secret: client_secret,
      company_name: company_name,
      regex_matcher: regex_matcher,
      admin_users: admin_users,
      url: url,
      app_name: app_name
    }
  end

  post '/config' do
    Cache.set(:google_client_id, params[:google_client_id])
    Cache.set(:google_client_secret, params[:google_client_secret])
    Cache.set(:company_name, params[:company_name])
    Cache.set(:regex_matcher, params[:regex_matcher])
    Cache.set(:admin_users, params[:admin_users])
    Cache.set(:url, params[:url])
    Cache.set(:app_name, params[:app_name])
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
    haml :force_login, locals: { company_name: Cache.get(:company_name) }, layout: false
  end

  get '/unauthorized' do
    "You are not authorized to use this application"
  end

  get '/logout' do
    session[:email] = nil
    redirect('/')
  end

  get '/auth/google_oauth2/callback' do
    session[:email] = env['omniauth.auth'].info.email
    redirect('/')
  end

  get '/auth/failure' do
    content_type 'text/plain'
    "failure: "+ request.env['omniauth.auth'].to_hash.inspect rescue "No Data"
  end

  def is_admin_user?
    Cache.get(:admin_users).split(',').any?{|admin_email| admin_email == session[:email]}
  end

  def logged_in?
    !!session[:email]
  end

  def logged_in_and_matches_regex?
    return false unless logged_in?
    domain_name = session[:email].split("@", 2).last
    domain_name =~ Regexp.new(Cache.get(:regex_matcher))
  end

  # Assets
  set :assets_precompile, %w(application.css *.png)
  register Sinatra::AssetPipeline

  # Development
  configure :development do
    require 'pry'
  end

end
