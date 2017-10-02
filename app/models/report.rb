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

   def self.lib_hit_rate(classification)
      data = {labels:[], data:[]}
      libraries = []
      query = []
      if classification.downcase == "any"
         libraries = ShelfListing.distinct.pluck(:library).sort
      else
         libraries = ShelfListing.where("classification=?", classification).distinct.pluck(:library).sort
      end

      libraries.each do | lib |
         # Both of these queries need to acount for classificaton being set
         tj="inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         total = 0
         if classification.downcase == "any"
            total = ShelfListing.joins(tj).where("library=? and active=? and origin>?", lib,1,0).pluck("shelf_listings.id").uniq.count
         else
            total = ShelfListing.joins(tj).where("library=? and classification=? and active=? and origin>?", lib,classification,1,0)
               .pluck("shelf_listings.id").uniq.count
         end

         j = "inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         j << " inner join barcode_interventions i on b.id = i.barcode_id"

         cnt = 0
         if classification.downcase == "any"
            cnt = ShelfListing.joins(j).where(library: lib).count
         else
            cnt = ShelfListing.joins(j).where(library: lib).where( classification: classification ).count
         end
         pct = ((cnt.to_f/total.to_f)*100.0).round(2)
         data[:data] << pct
         data[:labels] << "#{lib}|#{total}|#{cnt}"
      end
      return data
   end

   def self.classification_hit_rate(library, system)
      data = {labels:[], data:[]}
      classes = []
      if library.downcase != "any"
         classes = ShelfListing.where(library: library, classification_system: system)
            .distinct.pluck(:classification).sort
      else
         classes = ShelfListing.where(classification_system: system)
            .distinct.pluck(:classification).sort
      end

      classes.each do |clazz|
         # only consider books that have a stacks item ID or barcode from a cataloging
         # request. These are books that were actually found
         tj="inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         total = 0
         if library.downcase == "any"
            total = ShelfListing.joins(tj).where(
               "classification_system=? and classification=? and active=? and origin>?", system,clazz,1,0)
               .pluck("shelf_listings.id").uniq.count
         else
            total = ShelfListing.joins(tj).where(
               "classification_system=? and library=? and classification=? and active=? and origin>?",
               system,library,clazz,1,0)
               .pluck("shelf_listings.id").uniq.count
         end

         j = "inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         j << " inner join barcode_interventions i on b.id = i.barcode_id"
         cnt = 0
         if library.downcase == "any"
            cnt = ShelfListing.joins(j).where(classification: clazz).where(classification_system: system).count
         else
            cnt = ShelfListing.joins(j).where(classification: clazz).where(classification_system: system).where(library: library).count
         end
         if cnt > 0
            pct = ((cnt.to_f/total.to_f)*100.0).round(2)
            data[:data] << pct
            data[:labels] << "#{clazz}|#{total}|#{cnt}"
         end
      end
      return data
   end

   def self.subclassification_hit_rate(library, system, classification)
      # System and classification are both required. Library may be Any
      data = {labels:[], data:[]}
      subclasses = []

      if library.downcase == "any"
         subclasses = ShelfListing.where(classification_system: system).where(classification: classification)
            .distinct.pluck(:subclassification).sort
      else
         subclasses = ShelfListing.where(classification_system: system)
            .where(classification: classification).where(library: library)
            .distinct.pluck(:subclassification).sort
      end

      subclasses.each do | subclass |
         # only consider books that have a stacks item ID or barcode from a cataloging
         # request. These are books that were actually found
         tj="inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         total = 0
         if library.downcase == "any"
            q = "classification_system=? and subclassification=? and active=1 and origin > 0"
            total = ShelfListing.joins(tj).where(q, system, subclass)
               .pluck("shelf_listings.id").uniq.count
         else
            q = "library=? and classification_system=? and subclassification=? and active=1 and origin > 0"
            total = ShelfListing.joins(tj).where(q, library, system, subclass)
               .pluck("shelf_listings.id").uniq.count
         end

         j = "inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
         j << " inner join barcode_interventions i on b.id = i.barcode_id"
         cnt = 0
         if library.downcase == "any"
            cnt = ShelfListing.joins(j).where(classification_system: system)
               .where(subclassification: subclass).count
         else
            cnt = ShelfListing.joins(j).where(classification_system: system)
               .where(subclassification: subclass).where(library: library)
               .count
         end
         if cnt > 0
            pct = ((cnt.to_f/total.to_f)*100.0).round(2)
            data[:data] << pct
            data[:labels] << "#{subclass}|#{total}|#{cnt}"
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

   def self.decade_hit_rate(library)
      data = {labels:[], data:[]}

      # get all decades
      dc = "select distinct FLOOR(publication_year/10)*10 AS decade from shelf_listings where publication_year > 1000 order by decade asc"
      decades = ShelfListing.connection.execute(dc)

      # setup the joins to get listings without and with interventions
      j_all = "inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
      j_i = "#{j_all} inner join barcode_interventions i on b.id = i.barcode_id"

      # first get the counts for listings with no or invalid pub year
      if library.downcase == "any"
         total = ShelfListing.joins(j_all)
            .where("(publication_year is null or publication_year<1000) and active=? and origin>?", 1,0)
            .pluck("shelf_listings.id").uniq.count
         total_i = ShelfListing.joins(j_i)
            .where("(publication_year is null or publication_year<1000)")
            .pluck("shelf_listings.id").uniq.count
      else
         total = ShelfListing.joins(j_all)
            .where("(publication_year is null or publication_year<1000) and library=? and active=? and origin>?", library,1,0)
            .pluck("shelf_listings.id").uniq.count
         total_i = ShelfListing.joins(j_i)
            .where("(publication_year is null or publication_year<1000) and library=?", library)
            .pluck("shelf_listings.id").uniq.count
      end
      pct = ((total_i.to_f/total.to_f)*100.0).round(2)
      data[:data] << pct
      data[:labels] << "No Year|#{total}|#{total_i}"

      # Get counts for each decade
      decades.each do |decade|
         y0 = decade[0].to_i
         y1 = y0+9
         if library.downcase == "any"
            total = ShelfListing.joins(j_all)
               .where("publication_year>=? and publication_year<=? and active=? and origin>?", y0,y1,1,0)
               .pluck("shelf_listings.id").uniq.count
            total_i = ShelfListing.joins(j_i)
               .where("publication_year>=? and publication_year<=?", y0,y1)
               .pluck("shelf_listings.id").uniq.count
         else
            total = ShelfListing.joins(j_all)
               .where("publication_year>=? and publication_year<=? and library=? and active=? and origin>?", y0,y1,library,1,0)
               .pluck("shelf_listings.id").uniq.count
            total_i = ShelfListing.joins(j_i)
               .where("publication_year>=? and publication_year<=? and library=?", y0,y1,library)
               .pluck("shelf_listings.id").uniq.count
         end
         if total_i >= 20
            pct = ((total_i.to_f/total.to_f)*100.0).round(2)
            data[:data] << pct
            data[:labels] << "#{y0}|#{total}|#{total_i}"
         end
      end
      return data
   end
end
