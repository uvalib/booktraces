class CreateProblems < ActiveRecord::Migration[5.1]
  def change
    create_table :problems do |t|
      t.string :name
      t.references :cataloging_request, index: true, foreign_key: true
    end
  end
end
