class FixColumnTypes < ActiveRecord::Migration[5.1]
   def change
      reversible do |dir|
         dir.up do
            change_column :shelf_listings, :author, :string
            change_column :shelf_listings, :publication_year, :string
         end
         dir.down do
            change_column :shelf_listings, :author, :text
            change_column :shelf_listings, :publication_year, :text
         end
      end
   end
end
