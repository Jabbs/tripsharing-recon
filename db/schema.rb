# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150516181115) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "listings", force: true do |t|
    t.string   "source"
    t.string   "url",                              null: false
    t.datetime "published_at"
    t.text     "title"
    t.text     "content"
    t.string   "name"
    t.string   "profile_url"
    t.string   "location"
    t.string   "unparsed_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "latitude"
    t.float    "longitude"
    t.text     "trip_destination",    default: ""
    t.text     "trip_status",         default: ""
    t.datetime "trip_departs_at"
    t.datetime "trip_returns_at"
    t.text     "trip_duration",       default: ""
    t.text     "trip_type",           default: ""
    t.text     "trip_traveling_by",   default: ""
    t.text     "trip_staying_in",     default: ""
    t.text     "gender",              default: ""
    t.text     "age",                 default: ""
    t.text     "relationship_status", default: ""
    t.text     "nationality",         default: ""
  end

  add_index "listings", ["url"], name: "index_listings_on_url", unique: true, using: :btree

end
