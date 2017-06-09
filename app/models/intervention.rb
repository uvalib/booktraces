class Intervention < ApplicationRecord
   has_many :barcode_interventions
   has_many :barcodes, through:  :barcode_interventions

   has_many :intervention_details
   has_many :details, through: :intervention_details, :class_name=>"InterventionType", :source=>:intervention_type

   validates :who_found, presence: true
   validates :found_at, presence: true

end
