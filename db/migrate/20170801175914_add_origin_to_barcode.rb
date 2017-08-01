class AddOriginToBarcode < ActiveRecord::Migration[5.1]
  def change
     remove_column :shelf_listings, :item_id, :string
     add_column :barcodes, :origin, :integer, default: 0  # enum origin: [:original, :shelf, :catalog_request]
  end
end
