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

  use Rack::Session::Cookie, :key => 'rack.session',
    :path => '/',
    :expire_after => 86400, # 1 day
    :secret => ENV['SESSION_SECRET'] || '*&(^B234'

  use OmniAuth::Builder do
    provider :recurse_center, ENV['RC_ID'], ENV['RC_SECRET']
  end
end

get "/" do
  if session[:uid]
    @user = User.where(id: session[:uid]).first
    @batches = access_token_get(session[:token], "https://recurse.com/api/v1/batches")

    if @user.nil?
      error 500
    else
      erb :index
    end
  else
    redirect "/auth/recurse_center"
  end
end

%w(get post).each do |method|
  send(method, "/auth/:provider/callback") do
    # https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
    # #<OmniAuth::AuthHash
    # batch=#<OmniAuth::AuthHash end_date="2015-07-02" id=18 name="Spring 2, 2015" start_date="2015-03-30">
    # batch_id=18
    # bio="I'm originally from San Francisco (and the surrounding area), but I've spent the last year or so living in London. I've previously worked at Google, iFixit, Adode and Punchd. \r\n\r\nBeyond that, I'm a contributor to Fog (a ruby library for managing the cloud), and spend a lot of time thinking about managing distributed systems and deploying code. I like consuming and creating \"Art\" (painting, photography, music, books, old, new, street, whatever) and enjoy a good game of D&D.\r\n\r\nI love a good cup of coffee or pint of beer, and a nice long walk to find either.\r\n\r\nI'm currently unemployed and considering jobs in New York, Seattle and the Bay Area."
    # email="nat@natwelch.com"
    # first_name="Nat"
    # github="icco"
    # has_photo=true
    # id=1150
    # image="https://d29xw0ra2h4o4u.cloudfront.net/assets/people/nat_welch_150-6e067d098ed9324e3627df919f656a89.jpg"
    # is_faculty=false
    # is_hacker_schooler=true
    # job=nil
    # last_name="Welch"
    # links=[#<OmniAuth::AuthHash title="natwelch.com" url="http://natwelch.com">] middle_name=nil phone_number="+17077998675" projects=[#<OmniAuth::AuthHash description="My blog for interesting links and daily posts about RC. Hand coded in go. https://github.com/icco/natnatnat" title="Nat? Nat. Nat!" url="https://writing.natwelch.com/">, #<OmniAuth::AuthHash description="Hyperspace is a multiplayer version of Asteroids. https://github.com/kenpratt/hyperspace" title="Hyperspace" url="http://playhyperspace.com/">, #<OmniAuth::AuthHash description="A p2p audio streaming app built entirely in javascript for hosting silent dance parties. https://github.com/pselle/shhparty" title="ShhParty" url="http://shhparty.herokuapp.com/">, #<OmniAuth::AuthHash description="A ruby site for tracking how much I work on personal projects. https://github.com/icco/code.natwelch.com" title="Nat's Code" url="http://code.natwelch.com/">]
    # skills=["java", "ruby", "Linux", "git", "php", "golang", "distributed systems", "google cloud", "python"]
    # twitter="icco">

    session[:uid] = env['omniauth.auth']['uid']
    session[:token] = env['omniauth.auth']['credentials']['token']

    u = User.find_or_create_by(id: session[:uid])
    u.name = env['omniauth.auth']['info']['name']
    u.image = env['omniauth.auth']['info']['image']
    u.email = env['omniauth.auth']['info']['email']
    u.save

    redirect "/"
  end
end

get "/logout" do
  session[:uid] = nil
  redirect "/"
end

error 400..510 do
  @code = response.status
  erb :error
end

def access_token_get token, target

end
