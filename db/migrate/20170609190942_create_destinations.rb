class CreateDestinations < ActiveRecord::Migration[5.1]
  def change
    create_table :destinations do |t|
      t.references :destination_name
      t.string :date_sent_out
      t.string :bookplate
      t.timestamps
    end
  end
end
