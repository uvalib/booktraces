class BookStatus < ApplicationRecord
   validates :name, presence: true, uniqueness: true
end
