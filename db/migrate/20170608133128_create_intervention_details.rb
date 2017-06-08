class CreateInterventionDetails < ActiveRecord::Migration[5.1]
   def change
      create_table :intervention_details do |t|
         t.references :intervention, index: true, foreign_key: true
         t.references :intervention_type, index: true, foreign_key: true
      end
   end
end
