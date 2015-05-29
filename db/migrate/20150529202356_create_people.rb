class CreatePeople < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :image
      t.string :email

      t.timestamps null: false
    end
  end
end
