class Report
   def self.intervention_distribution
      total = Intervention.all.count
      chart = { labels:[], data:[]}
      InterventionType.all.each do |t|
         c = InterventionDetail.where(intervention_type_id: t.id).count
         chart[:data] << c
         p = ((c.to_f/total.to_f)*100.0).round(1)
         chart[:labels] << "#{t.category.capitalize}: #{t.name.capitalize} (#{c}/#{total} #{p}%)"
      end
      return chart
   end

   def self.library_hit_rate
      data = {labels:[], data:[]}
      ShelfListing.distinct.pluck(:library).each do |l|
         j = "inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         j << " inner join barcode_interventions i on b.id = i.barcode_id"
         total = ShelfListing.where(library: l).count
         cnt = ShelfListing.joins(j).where(library: l).count
         pct = ((cnt.to_f/total.to_f)*100.0).round(2)
         data[:data] << pct
         data[:labels] << "#{l}|#{total}|#{cnt}"
      end
      return data
   end

   def self.classification_hit_rate
      data = {labels:[], data:[]}
      ShelfListing.distinct.pluck(:classification).sort.each do |l|
         j = "inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         j << " inner join barcode_interventions i on b.id = i.barcode_id"
         total = ShelfListing.where(classification: l).count
         cnt = ShelfListing.joins(j).where(classification: l).count
         if cnt > 0
            pct = ((cnt.to_f/total.to_f)*100.0).round(2)
            data[:data] << pct
            data[:labels] << "#{l}|#{total}|#{cnt}"
         end
      end
      return data
   end
end
