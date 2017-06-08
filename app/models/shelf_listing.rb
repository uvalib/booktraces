class ShelfListing < ApplicationRecord

   has_many :barcodes
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
      self.classification_system = "LC" if self.classification_system.blank?
   end

   def barcode
      self.barcodes.where(active: 1).pluck(:barcode)
   end
end
