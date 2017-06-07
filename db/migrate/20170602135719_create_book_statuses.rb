class CreateBookStatuses < ActiveRecord::Migration[5.1]
  def change
    create_table :book_statuses do |t|
      t.string :name
    end
  end
end
