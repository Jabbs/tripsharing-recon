class CreateListings < ActiveRecord::Migration
  def change
    create_table :listings do |t|
      t.string :source
      t.string :url, null: false
      t.datetime :published_at
      t.text :title
      t.text :content
      t.string :name
      t.string :profile_url
      t.string :location
      t.string :unparsed_date

      t.timestamps
    end
    add_index :listings, :url, unique: true
  end
end
