class ApiKey < ApplicationRecord
   validates :email, presence: true, uniqueness: true
   validates :key, uniqueness: true
   has_secure_token :key
end
