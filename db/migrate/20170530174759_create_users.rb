class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :computing_id
      t.string :last_name
      t.string :first_name
      t.boolean :is_active
      t.timestamps
    end
  end
end
