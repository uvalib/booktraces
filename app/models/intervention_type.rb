class InterventionType < ApplicationRecord
   enum category: [:inscription, :annotation, :marginalia, :insertion, :artwork, :library]

   validates :name, presence: true, uniqueness: {scope: :category}
   validates :category, presence: true
end
