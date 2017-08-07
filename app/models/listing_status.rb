class ListingStatus < ApplicationRecord

   def self.statuses
      ListingStatus.distinct.pluck(:result).sort
   end
end
