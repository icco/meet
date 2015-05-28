class Tweet < ActiveRecord::Base

  # Given a hashtag, scrape twitter for more tweets about it.
  def self.get_more hashtag
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['CONSUMER_KEY']
      config.consumer_secret     = ENV['CONSUMER_SECRET']
      config.access_token        = ENV['ACCESS_TOKEN']
      config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
    end

    p client

    client.search("##{hashtag}", result_type: "mixed").each do |tweet|
      t = Tweet.find_or_create_by(link: "https://twitter.com/statuses/#{tweet.id}")
      t.screenname = tweet.user.screen_name
      t.text = tweet.text
      t.posted = tweet.created_at
      t.hashtag = hashtag
      t.save
    end

    return Tweet.all.count
  end
end
