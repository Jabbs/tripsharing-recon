class CreateListings < ActiveRecord::Migration
  def change
    create_table :listings do |t|
      t.string :source
      t.string :url
      t.datetime :published_at
      t.text :title
      t.text :content
      t.string :name
      t.string :profile_url

      t.timestamps
    end
  end
end
