class CreateInterventionTypes < ActiveRecord::Migration[5.1]
  def change
    create_table :intervention_types do |t|
      t.integer :category
      t.string :name
    end
  end
end
