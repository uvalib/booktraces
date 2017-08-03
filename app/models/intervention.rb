class Intervention < ApplicationRecord
   has_one :barcode_intervention
   has_one :barcode, through:  :barcode_intervention

   has_many :intervention_details
   has_many :details, through: :intervention_details, :class_name=>"InterventionType", :source=>:intervention_type

   validates :who_found, presence: true
   validates :found_at, presence: true

end
