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

ActiveRecord::Schema.define(version: 2019_03_06_190107) do

  create_table "api_keys", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "institution"
    t.string "key", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_api_keys_on_key", unique: true
  end

  create_table "barcode_destinations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "destination_id"
    t.bigint "barcode_id"
    t.index ["barcode_id"], name: "index_barcode_destinations_on_barcode_id"
    t.index ["destination_id"], name: "index_barcode_destinations_on_destination_id"
  end

  create_table "barcode_interventions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "intervention_id"
    t.bigint "barcode_id"
    t.index ["barcode_id"], name: "index_barcode_interventions_on_barcode_id"
    t.index ["intervention_id"], name: "index_barcode_interventions_on_intervention_id"
  end

  create_table "barcodes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "barcode"
    t.boolean "active", default: true
    t.bigint "shelf_listing_id"
    t.bigint "cataloging_request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "origin", default: 0
    t.index ["cataloging_request_id"], name: "index_barcodes_on_cataloging_request_id"
    t.index ["shelf_listing_id"], name: "index_barcodes_on_shelf_listing_id"
  end

  create_table "cataloging_requests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "shelf_listing_id"
    t.date "sent_out_on"
    t.date "returned_on"
    t.string "destination"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "problems"
    t.index ["shelf_listing_id"], name: "index_cataloging_requests_on_shelf_listing_id"
  end

  create_table "destination_names", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
  end

  create_table "destinations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "destination_name_id"
    t.string "date_sent_out"
    t.string "bookplate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_name_id"], name: "index_destinations_on_destination_name_id"
  end

  create_table "intervention_details", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "intervention_id"
    t.bigint "intervention_type_id"
    t.index ["intervention_id"], name: "index_intervention_details_on_intervention_id"
    t.index ["intervention_type_id"], name: "index_intervention_details_on_intervention_type_id"
  end

  create_table "intervention_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "category"
    t.string "name"
  end

  create_table "interventions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "special_interest"
    t.text "special_problems"
    t.string "who_found"
    t.datetime "found_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "listing_statuses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.date "date_checked"
    t.string "who_checked"
    t.string "actions"
    t.string "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shelf_listings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "internal_id", null: false
    t.text "title"
    t.string "author"
    t.string "publication_year"
    t.string "call_number"
    t.string "bookplate_text"
    t.string "location"
    t.string "library"
    t.string "classification", limit: 10
    t.string "subclassification", limit: 10
    t.string "classification_system"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "listing_status_id"
    t.index ["internal_id"], name: "index_shelf_listings_on_internal_id"
    t.index ["listing_status_id"], name: "index_shelf_listings_on_listing_status_id"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "computing_id"
    t.string "last_name"
    t.string "first_name"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "barcode_destinations", "barcodes"
  add_foreign_key "barcode_destinations", "destinations"
  add_foreign_key "barcode_interventions", "barcodes"
  add_foreign_key "barcode_interventions", "interventions"
  add_foreign_key "barcodes", "cataloging_requests"
  add_foreign_key "barcodes", "shelf_listings"
  add_foreign_key "cataloging_requests", "shelf_listings"
  add_foreign_key "destinations", "destination_names"
  add_foreign_key "intervention_details", "intervention_types"
  add_foreign_key "intervention_details", "interventions"
  add_foreign_key "shelf_listings", "listing_statuses"
end
