class CatalogingRequest < ApplicationRecord
   belongs_to :shelf_listing
   has_many :problem_types

   validates :shelf_listing, presence: true
   validates :updated_item_id, presence: true
end
