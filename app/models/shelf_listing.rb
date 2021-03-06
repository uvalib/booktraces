class ShelfListing < ApplicationRecord

   has_many :barcodes
   has_many :cataloging_requests
   belongs_to :listing_status, optional: true

   has_many :interventions, through: :barcodes
   has_many :destinations, through: :barcodes

   validates :internal_id, presence: true, uniqueness: true
   validates :library, presence: true
   validates :classification, presence: true
   validates :subclassification, presence: true

   before_save do
      self.classification_system = "LC" if self.classification_system.blank?
   end

   def item_id
      bc = barcodes.where(origin: "sirsi").first
      if bc.nil?
         bc = barcodes.where(active: 1).first
      end
      return bc.barcode
   end

   def active_barcodes
      bcs = []
      barcodes.each do |bc|
         next if !bc.active
         bcs << bc.barcode
      end
      return bcs
   end

   def self.libraries
      return ShelfListing.pluck(:library).uniq.sort.unshift('Any')
   end

   def self.classifications(include_any = true)
      out = ShelfListing.pluck(:classification).uniq.sort
      if include_any
         return out.unshift('Any')
      else
         return out
      end
   end

   def self.subclassifications
      return ShelfListing.pluck(:subclassification).uniq.sort.unshift('Any')
   end

end
