# join table to relate intervention a list of specific types of intervention
#
class InterventionDetail < ApplicationRecord
   belongs_to :intervention_type
   belongs_to :intervention

   validates :intervention_type, presence: true
   validates :intervention, presence: true
end
