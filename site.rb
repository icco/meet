require "rubygems"
require "bundler"
Bundler.require(:default, ENV["RACK_ENV"] || :development)
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

configure do
  RACK_ENV = (ENV['RACK_ENV'] || :development).to_sym
  connections = {
    :development => "postgres://localhost/meet",
    :test => "postgres://postgres@localhost/meet_test",
    :production => ENV['DATABASE_URL']
  }

  url = URI(connections[RACK_ENV])
  options = {
    :adapter => url.scheme,
    :host => url.host,
    :port => url.port,
    :database => url.path[1..-1],
    :username => url.user,
    :password => url.password
  }

  case url.scheme
  when "sqlite"
    options[:adapter] = "sqlite3"
    options[:database] = url.host + url.path
  when "postgres"
    options[:adapter] = "postgresql"
  end
  set :database, options

  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] || '*&(^B234'

  use OmniAuth::Builder do
    provider :recurse_center, ENV['RC_ID'], ENV['RC_SECRET']
  end
end

get "/" do
  if session[:uid] and !env['omniauth.auth'].nil?
    @hash = env['omniauth.auth'].info
    erb :index
  else
    redirect "/auth/recurse_center"
  end
end

%w(get post).each do |method|
  send(method, "/auth/:provider/callback") do
    # https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
    session[:uid] = env['omniauth.auth'].uid
    session[:code] = params["code"]
    session[:state] = params["state"]

    redirect "/"
  end
end

error 400..510 do
  @code = response.status
  erb :error
end
