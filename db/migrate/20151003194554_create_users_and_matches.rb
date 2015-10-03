class CreateUsersAndMatches < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :image
      t.string :email
      t.integer :frequency
      t.boolean :available

      t.timestamps null: false
    end

    create_table :matches do |t|
      t.integer :a_id
      t.integer :b_id
      t.boolean :met

      t.timestamps null: false
    end
  end
end
