class CreateBarcodeInterventions < ActiveRecord::Migration[5.1]
   def change
      create_table :barcode_interventions do |t|
         t.references :intervention, index: true, foreign_key: true
         t.references :barcode, index: true, foreign_key: true
      end
   end
end
