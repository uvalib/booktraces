class CreateBarcodeDestinations < ActiveRecord::Migration[5.1]
  def change
    create_table :barcode_destinations do |t|
      t.references :destination, index: true, foreign_key: true
      t.references :barcode, index: true, foreign_key: true
    end
  end
end
