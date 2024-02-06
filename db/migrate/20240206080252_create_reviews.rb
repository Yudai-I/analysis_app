class CreateReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :reviews do |t|
      t.text :review, null: false

      t.timestamps
    end
  end
end
