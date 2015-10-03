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

  if !RACK_ENV.eql? :development
    # Force HTTPS
    use Rack::SslEnforcer
  end

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

  use Rack::Session::Cookie, :key => 'rack.session',
    :path => '/',
    :expire_after => 86400, # 1 day
    :secret => ENV['SESSION_SECRET'] || '*&(^B234'

  use OmniAuth::Builder do
    provider :recurse_center, ENV['RC_ID'], ENV['RC_SECRET']
  end
end

# God I love filters!
before do
  # pass the filter if still in auth phase
  pass if /^\/(auth\/|logout).*/.match(request.path_info)

  # setup current_user if the user is logged in
  if session[:uid]
    @current_user = User.where(id: session[:uid]).first
  else
    redirect "/auth/recurse_center"
  end
end

%w(get post).each do |method|
  send(method, "/auth/:provider/callback") do
    # https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
    session[:uid] = env["omniauth.auth"]["uid"]
    session[:token] = env["omniauth.auth"]["credentials"]["token"]

    u = User.find_or_create_by(id: session[:uid])
    u.name = env["omniauth.auth"]["info"]["name"]
    u.image = env["omniauth.auth"]["info"]["image"]
    u.email = env["omniauth.auth"]["info"]["email"]
    u.frequency = 0
    u.available = false
    u.save

    redirect "/"
  end
end

get "/" do
  erb :index
end

get "/logout" do
  session[:uid] = nil
  redirect "/"
end

error 400..510 do
  @code = response.status
  erb :error
end
