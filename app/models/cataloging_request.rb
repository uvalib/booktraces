class CatalogingRequest < ApplicationRecord
   belongs_to :shelf_listing
   has_one :barcode
   has_many :problem_types

   validates :shelf_listing, presence: true
end
