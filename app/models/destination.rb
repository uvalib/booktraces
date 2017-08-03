class Destination < ApplicationRecord
   belongs_to :destination_name

   has_one :barcode_destination
   has_one :barcode, through:  :barcode_destination

   validates :destination_name, presence: true
end
