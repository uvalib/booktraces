class RenameOriginalItemId < ActiveRecord::Migration[5.1]
  def change
      rename_column :shelf_listings, :original_item_id, :item_id
  end
end
