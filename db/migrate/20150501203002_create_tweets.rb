class CreateTweets < ActiveRecord::Migration
  def change
    create_table :tweets do |t|
      t.text :text
      t.datetime :posted
      t.string :hashtag
      t.string :screenname
    end
  end
end
