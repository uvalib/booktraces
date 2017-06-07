class User < ApplicationRecord
   validates :computing_id, presence:true, uniqueness:true
end
