class CreateReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :reviews do |t|
      t.text :review, null: false
      t.text :link, null: false
      t.string :product_name, null: false
      t.string :image_url, null: false
      t.integer :user_id, null: false
      t.timestamps
    end
  end
end
