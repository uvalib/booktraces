class CreateInterventions < ActiveRecord::Migration[5.1]
  def change
    create_table :interventions do |t|
      t.text :special_interest
      t.text :special_problems
      t.string :who_found
      t.datetime :found_at
      t.timestamps
    end
  end
end
