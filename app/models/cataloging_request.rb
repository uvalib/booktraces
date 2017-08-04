class CatalogingRequest < ApplicationRecord
   belongs_to :shelf_listing
   has_one :barcode

   validates :shelf_listing, presence: true
end
