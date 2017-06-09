class Destination < ApplicationRecord
   validates :name, presence: true, uniqueness: true
end
