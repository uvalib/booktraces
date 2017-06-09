class Destination < ApplicationRecord
   belongs_to :destination_name

   has_many :barcode_destinations
   has_many :barcodes, through:  :barcode_destinations

   validates :destination_name, presence: true
end
