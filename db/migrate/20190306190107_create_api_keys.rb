class CreateApiKeys < ActiveRecord::Migration[5.2]
   def change
      reversible do |dir|
         dir.up do
            create_table :api_keys do |t|
              t.string :email, unique: true, null: false
              t.string :first_name
              t.string :last_name
              t.string :institution
              t.string :key, index: {unique: true}, null: false
              t.boolean :active, default: true
              t.timestamps
            end
            ApiKey.create(email:"booktraces",first_name:"book", last_name: "traces", institution: "UVA")
         end
         dir.down do
            drop_table :api_keys
         end
      end
   end
end
