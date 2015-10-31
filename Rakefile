require "rubygems"
require "bundler"
Bundler.require(:default, ENV["RACK_ENV"] || :development)

require "sinatra/activerecord/rake"
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

namespace :db do
  task :load_config do
    require "./site"
  end
end

desc "Run a local server."
task :local do
  Kernel.exec("shotgun -s thin -p 9393")
end

desc "Run Cron"
task :cron => ["db:load_config"] do
  users = User.where(available: true).order("RANDOM()")
  (0 .. users.length).step(2).each do |i|
    if users[i+1].nil?
      break
    end
    m = Match.new(a: users[i],
                  b: users[i+1],
                  met: false)
    m.save
    users[i].available = false
    users[i].save
    users[i+1].available = false
    users[i+1].save
  end
end


task :generate_data => ["db:load_config"] do
  available_frequencies = [0, 1, 7, 30, 90]
  (0..99).each do |i|
    user = User.new(name: i,
             available: true,
             frequency: available_frequencies.sample)
    user.save
  end
  p User.count
end
