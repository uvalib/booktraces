class CreateShelfListings < ActiveRecord::Migration[5.1]
  def change
    create_table :shelf_listings do |t|
      t.string :internal_id, index: true, null: false
      t.string :original_item_id, index: true
      t.string :stacks_item_id, index: true
      t.references :book_status, index: true, foreign_key: true
      t.text :title
      t.text :author
      t.text :publication_year
      t.string :call_number
      t.string :bookplate_text
      t.string :location
      t.string :library
      t.string :classification, limit: 10
      t.string :subclassification, limit: 10
      t.string :classification_system
      t.date :date_checked
      t.string :who_checked
      t.timestamps
    end
  end
end
