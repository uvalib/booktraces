class BarcodeDestination < ApplicationRecord
   belongs_to :barcode
   belongs_to :destination

   validates :barcode, presence: true
   validates :destination, presence: true
end
