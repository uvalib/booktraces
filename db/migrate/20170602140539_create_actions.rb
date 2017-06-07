class CreateActions < ActiveRecord::Migration[5.1]
  def change
    create_table :actions do |t|
      t.string :name
      t.references :shelf_listing, index: true, foreign_key: true
   end
  end
end
