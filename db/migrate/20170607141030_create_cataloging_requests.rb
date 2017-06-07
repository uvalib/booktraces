class CreateCatalogingRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :cataloging_requests do |t|
      t.references :shelf_listing, index: true, foreign_key: true
      t.date :sent_out_on
      t.date :returned_on
      t.string :updated_item_id
      t.string :destination
      t.timestamps
    end
  end
end
