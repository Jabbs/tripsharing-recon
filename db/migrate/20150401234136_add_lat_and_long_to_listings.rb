class AddLatAndLongToListings < ActiveRecord::Migration
  def change
    add_column :listings, :latitude, :string
    add_column :listings, :longitude, :string
  end
end
