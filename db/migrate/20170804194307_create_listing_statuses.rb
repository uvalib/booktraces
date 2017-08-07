class CreateListingStatuses < ActiveRecord::Migration[5.1]
   # faux models necessary for migration
   class BookStatus < ApplicationRecord
   end
   class Action < ApplicationRecord
   end
   class ShelfListing < ApplicationRecord
      has_many :actions
      belongs_to :book_status
      belongs_to :listing_status
   end

  def up
    puts "Create new listing status model..."
    create_table :listing_statuses do |t|
      t.date :date_checked
      t.string :who_checked
      t.string :actions
      t.string :result
      t.timestamps
    end

    puts "Shelf listings have reference to status..."
    add_reference :shelf_listings, :listing_status, foreign_key: true, index: true

    puts "Migrate prior actions / book status into new listing status..."
    ShelfListing.all.find_each do |sl|
      acts = sl.actions.map { |a| a.name.capitalize}.join(', ')
      ls = ListingStatus.create(who_checked: sl.who_checked, date_checked: sl.date_checked, actions: acts, result: sl.book_status.name)
      sl.update(listing_status: ls)
    end

    puts "Clean up now defunct models..."
    drop_table :actions

    remove_reference :shelf_listings, :book_status, foreign_key: true, index: true
    drop_table :book_statuses
  end

  def down
     puts "CANNOT BE ROLLED BACK"
  end
end
