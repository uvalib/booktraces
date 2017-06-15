class User < ApplicationRecord
   validates :computing_id, presence:true, uniqueness:true

   def full_name
      return "#{self.first_name} #{self.last_name}"
   end
end
