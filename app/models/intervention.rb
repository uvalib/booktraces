class Intervention < ApplicationRecord
   belongs_to :barcode
   has_and_belongs_to_many :intervention_types, :join_table=>:intervention_details

   validates :barcode, presence: true
   validates :who_found, presence: true
   validates :found_at, presence: true

   def details
      return self.intervention_types
   end
end
