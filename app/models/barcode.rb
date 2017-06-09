class Barcode < ApplicationRecord
   belongs_to :shelf_listing
   belongs_to :cataloging_request, optional: true

   has_one :barcode_intervention
   has_one :intervention, through: :barcode_intervention
   has_one :barcode_destination
   has_one :destination, through: :barcode_destination

   validates :shelf_listing, presence: true
   validates :barcode, presence: true
end
