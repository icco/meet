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
task :cron => [:match_people, :update_availability]

desc "Generate Matches for Available peeps."
task :match_people => ["db:load_config"] do
  match_count = 0
  users = User.where(available: true).order("RANDOM()")
  (0 .. users.length).step(2).each do |i|
    if users[i+1].nil?
      break
    end

    # Create Match
    m = Match.new(a: users[i],
                  b: users[i+1],
                  met: false)
    m.save
    match_count += 1
  end

  puts "Generated #{match_count} matches."
end

desc "Update availability of users."
task :update_availability => ["db:load_config"] do
  puts "Before update: #{User.where(available: true).count} available."
  User.where(frequency: 0).update_all(available: false)
  User.where("frequency > 0").each do |u|
    last_match = Match.where("a_id = ? or b_id = ?", u.id, u.id).order(created_at: :desc).first
    u.available = (Time.now - last_match.created_at) > (u.frequency * 60 * 60 * 24)
    u.save
  end
  puts "After update: #{User.where(available: true).count} available."
end

desc "Generate random database data."
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
