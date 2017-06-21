class ShelfListing < ApplicationRecord

   has_many :barcodes
   has_many :cataloging_requests
   has_many :actions
   belongs_to :book_status

   has_many :interventions, through: :barcodes

   validates :internal_id, presence: true, uniqueness: true
   validates :original_item_id, presence: true
   validates :book_status, presence: true
   validates :library, presence: true
   validates :classification, presence: true
   validates :subclassification, presence: true

   before_save do
      self.classification_system = "LC" if self.classification_system.blank?
   end

   def active_barcodes
      bcs = []
      barcodes.each do |bc|
         next if !bc.active
         bcs << bc.barcode
      end
      if bcs.length == 0
         bcs =  [self.original_item_id]
      end
      return bcs
   end

   def self.libraries
      return ShelfListing.pluck(:library).uniq.sort.unshift('Any')
   end

   def self.classifications
      out = ShelfListing.pluck(:classification).uniq.sort
      return out.unshift('Any')
   end

   def self.subclassifications
      return ShelfListing.pluck(:subclassification).uniq.sort.unshift('Any')
   end

end
