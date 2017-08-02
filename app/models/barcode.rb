class Barcode < ApplicationRecord
   enum origin: [:sirsi, :stacks, :cataloging_request, :user_edit]

   belongs_to :shelf_listing, optional: true
   belongs_to :cataloging_request, optional: true

   has_one :barcode_intervention
   has_one :intervention, through: :barcode_intervention
   has_one :barcode_destination
   has_one :destination, through: :barcode_destination

   validates :barcode, presence: true
   validates :origin, presence: true
end
