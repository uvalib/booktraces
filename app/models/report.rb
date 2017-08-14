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

         tj="inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         total = ShelfListing.joins(tj).where("library=? and active=? and origin>?", l,1,0).pluck("shelf_listings.id").uniq.count

         j = "inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         j << " inner join barcode_interventions i on b.id = i.barcode_id"

         cnt = ShelfListing.joins(j).where(library: l).count
         pct = ((cnt.to_f/total.to_f)*100.0).round(2)
         data[:data] << pct
         data[:labels] << "#{l}|#{total}|#{cnt}"
      end
      return data
   end

   def self.classification_hit_rate(system)
      data = {labels:[], data:[]}
      ShelfListing.where(classification_system: system).distinct.pluck(:classification).sort.each do |l|

         # only consider books that have a stacks item ID or barcode from a cataloging
         # request. These are books that were actually found
         tj="inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         total = ShelfListing.joins(tj).where("classification=? and active=? and origin>?", l,1,0).pluck("shelf_listings.id").uniq.count

         j = "inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         j << " inner join barcode_interventions i on b.id = i.barcode_id"
         cnt = ShelfListing.joins(j).where(classification: l).count
         if cnt > 0
            pct = ((cnt.to_f/total.to_f)*100.0).round(2)
            data[:data] << pct
            data[:labels] << "#{l}|#{total}|#{cnt}"
         end
      end
      return data
   end

   def self.subclassification_hit_rate(classification)
      data = {labels:[], data:[]}
      ShelfListing.where(classification: classification).distinct.pluck(:subclassification).sort.each do |l|
         # only consider books that have a stacks item ID or barcode from a cataloging
         # request. These are books that were actually found
         tj="inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         total = ShelfListing.joins(tj).where("subclassification=? and active=? and origin>?", l,1,0).pluck("shelf_listings.id").uniq.count

         j = "inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         j << " inner join barcode_interventions i on b.id = i.barcode_id"
         cnt = ShelfListing.joins(j).where(subclassification: l).count
         if cnt > 0
            pct = ((cnt.to_f/total.to_f)*100.0).round(2)
            data[:data] << pct
            data[:labels] << "#{l}|#{total}|#{cnt}"
         end
      end
      return data
   end

   def self.hit_rate_extremes( mode )
      data = {labels:[], data:[]}

      # get the total number of shelf listings for each subclassification
      tc = "select l.subclassification,count( l.subclassification) as cnt  from shelf_listings l"
      tc << " inner join barcodes b on l.id = b.shelf_listing_id"
      tc << " where b.active=1 and b.origin > 0"
      tc << " group by  l.subclassification order by cnt desc"
      totals = ShelfListing.connection.execute(tc)

      # Now get total number of interventions in each subcategory
      ic = "select l.subclassification,count( l.subclassification) as cnt  from shelf_listings l"
      ic << " inner join barcodes b on l.id = b.shelf_listing_id"
      ic << " inner join barcode_interventions i on b.id = i.barcode_id"
      ic << " where b.active=1 and b.origin > 0"
      ic << " group by  l.subclassification order by cnt desc"
      raw = []
      ShelfListing.connection.execute(ic).each do |iv|
         subclass = iv[0]
         total_info = totals.detect{ |(sc, t)| sc == subclass }
         next if total_info[1] < 20
         pct = ((iv[1].to_f/total_info[1].to_f)*100.0).round(2)
         label = "#{subclass}|#{total_info[1]}|#{iv[1]}"
         raw << {percent: pct, label: label}
      end

      raw.sort_by! { |hsh| hsh[:percent] }
      raw.reverse! if mode == :top
      raw = raw[0..25]
      raw.each do |v|
         data[:data] << v[:percent]
         data[:labels] << v[:label]
      end

      return data
   end
end
