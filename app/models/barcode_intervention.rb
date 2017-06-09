# join table to relate interventions to barcodes
#
class BarcodeIntervention < ApplicationRecord
   belongs_to :barcode
   belongs_to :intervention

   validates :barcode, presence: true
   validates :intervention, presence: true
end
