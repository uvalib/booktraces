class Barcode < ApplicationRecord
   belongs_to :shelf_listing
   belongs_to :cataloging_request, optional: true

   validates :shelf_listing, presence: true
   validates :barcode, presence: true
end
