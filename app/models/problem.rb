class Problem < ApplicationRecord
   validates :name, presence: true
   belongs_to :cataloging_request
end
