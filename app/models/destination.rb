class Destination < ApplicationRecord
   belongs_to :destination_name

   validates :destination_name, presence: true
end
