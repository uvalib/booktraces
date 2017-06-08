class CreateBarcodes < ActiveRecord::Migration[5.1]
  def change
    create_table :barcodes do |t|
      t.string :barcode
      t.boolean :active, default: true
      t.references :shelf_listing, index: true, foreign_key: true
      t.references :cataloging_request, index: true, foreign_key: true
      t.timestamps
    end
  end
end
