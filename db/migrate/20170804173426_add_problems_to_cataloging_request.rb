class AddProblemsToCatalogingRequest < ActiveRecord::Migration[5.1]
   class CatalogingRequest < ApplicationRecord
      has_many :problems
   end

  def up
     add_column :cataloging_requests, :problems_txt, :string
     CatalogingRequest.all.find_each do |cr|
        txt = cr.problems.map { |a| a.name.capitalize }.join(', ')
        cr.update(problems_txt: txt)
     end
     drop_table :problems
     rename_column :cataloging_requests, :problems_txt, :problems
  end

  def down
     remove_column :cataloging_requests, :problems, :string
     create_table :problems do |t|
       t.string :name
       t.references :cataloging_request, index: true, foreign_key: true
     end
  end
end
