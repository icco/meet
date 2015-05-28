class AddLink < ActiveRecord::Migration
  def change
    change_table :tweets do |t|
      t.string :link
    end
  end
end
