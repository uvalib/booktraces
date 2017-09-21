class DropCheckInfoFromListings < ActiveRecord::Migration[5.1]
  def change
      remove_column :shelf_listings, :who_checked, :string
      remove_column :shelf_listings, :date_checked, :date
  end
end
