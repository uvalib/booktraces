class ShelfListing < ApplicationRecord

   has_many :cataloging_requests
   has_many :actions
   belongs_to :book_status

   validates :internal_id, presence: true, uniqueness: true
   validates :original_item_id, presence: true
   validates :book_status, presence: true
   validates :library, presence: true
   validates :classification, presence: true
   validates :subclassification, presence: true

   before_save do
      self.stacks_item_id = nil if self.stacks_item_id.blank?
      self.classification_system = "LC" if self.classification_system.blank?
   end

   def item_id
      if cataloging_requests.count == 0
         return self.original_item_id if self.stacks_item_id.blank?
         return self.stacks_item_id
      else
         id = []
         self.cataloging_requests.each do |p|
            id << p.updated_item_id
         end
         return id
      end
   end
end
