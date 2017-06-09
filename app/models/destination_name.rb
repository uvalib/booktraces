class DestinationName < ApplicationRecord
   validates :name, presence: true, uniqueness: true
end
