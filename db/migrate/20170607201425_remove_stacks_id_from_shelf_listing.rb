class RemoveStacksIdFromShelfListing < ActiveRecord::Migration[5.1]
  def change
     remove_column :shelf_listings, :stacks_item_id, :string
     remove_column :cataloging_requests, :updated_item_id, :string
  end
end
