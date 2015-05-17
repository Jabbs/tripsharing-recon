class AddSomeColumnsToListings < ActiveRecord::Migration
  def change
    add_column :listings, :trip_destination, :text, default: ""
    add_column :listings, :trip_status, :text, default: ""
    add_column :listings, :trip_departs_at, :datetime
    add_column :listings, :trip_returns_at, :datetime
    add_column :listings, :trip_duration, :text, default: ""
    add_column :listings, :trip_type, :text, default: ""
    add_column :listings, :trip_traveling_by, :text, default: ""
    add_column :listings, :trip_staying_in, :text, default: ""
    add_column :listings, :gender, :text, default: ""
    add_column :listings, :age, :text, default: ""
    add_column :listings, :relationship_status, :text, default: ""
    add_column :listings, :nationality, :text, default: ""
  end
end
