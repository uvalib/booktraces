class CreateApiKeys < ActiveRecord::Migration[5.2]
  def change
    create_table :api_keys do |t|
      t.string :email, unique: true, null: false
      t.string :first_name
      t.string :last_name
      t.string :institution
      t.string :key, index: {unique: true}, null: false
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
