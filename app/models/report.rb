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

      # Common joins; first for all listings, second for listings with interventions
      join_all ="inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
      join_i = "#{join_all} inner join barcode_interventions i on b.id = i.barcode_id"

      gt = 0
      libraries.each do | lib |
         where_q = "library=#{sanitize(lib)} and active=1"
         if classification.downcase != "any"
            where_q << " and classification=#{sanitize(classification)}"
         end

         # get total listings matching criteria
         total = ShelfListing.joins(join_all).where(where_q).distinct.count
         gt+= total
         next if total < 20

         # get total listings matching criteria with interventions
         cnt = ShelfListing.joins(join_i).where(where_q).distinct.count
         if cnt > 0
            pct = ((cnt.to_f/total.to_f)*100.0).round(2)
            data[:data] << pct
            data[:labels] << "#{lib}|#{total}|#{cnt}"
         end
      end
      data[:total] = gt

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

      # Common joins; first for all listings, second for listings with interventions
      join_all ="inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
      join_i = "#{join_all} inner join barcode_interventions i on b.id = i.barcode_id"

      gt = 0
      classes.each do |clazz|
         where_q = "classification_system=#{sanitize(system)} and classification=#{sanitize(clazz)} and active=1"
         if library.downcase != "any"
            where_q << " and library=#{sanitize(library)}"
         end

         total = ShelfListing.joins(join_all).where(where_q).distinct.count
         gt+= total
         next if total < 20

         cnt = ShelfListing.joins(join_i).where(where_q).distinct.count
         if cnt > 0
            pct = ((cnt.to_f/total.to_f)*100.0).round(2)
            data[:data] << pct
            data[:labels] << "#{clazz}|#{total}|#{cnt}"
         end
      end
      data[:total] = gt

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

      # Common joins; first for all listings, second for listings with interventions
      join_all ="inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
      join_i = "#{join_all} inner join barcode_interventions i on b.id = i.barcode_id"

      gt = 0
      subclasses.each do | subclass |
         where_q = "classification_system=#{sanitize(system)} and subclassification=#{sanitize(subclass)} and active=1"
         if library.downcase != "any"
            where_q << " and library = #{sanitize(library)}"
         end

         total = ShelfListing.joins(join_all).where(where_q).distinct.count
         gt += total
         next if total < 20

         cnt = ShelfListing.joins(join_i).where(where_q).distinct.count
         if cnt > 0
            pct = ((cnt.to_f/total.to_f)*100.0).round(2)
            data[:data] << pct
            data[:labels] << "#{subclass}|#{total}|#{cnt}"
         end
      end
      data[:total] = gt

      return data
   end

   def self.hit_rate_extremes( mode )
      data = {labels:[], data:[]}

      # get the total number of shelf listings for each subclassification
      tc = "select l.subclassification,count( l.subclassification) as cnt  from shelf_listings l"
      tc << " inner join barcodes b on l.id = b.shelf_listing_id"
      tc << " where b.active=1"
      tc << " group by  l.subclassification order by cnt desc"
      totals = ShelfListing.connection.execute(tc)

      # Now get total number of interventions in each subcategory
      ic = "select l.subclassification,count( l.subclassification) as cnt  from shelf_listings l"
      ic << " inner join barcodes b on l.id = b.shelf_listing_id"
      ic << " inner join barcode_interventions i on b.id = i.barcode_id"
      ic << " where b.active=1"
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

   def self.decade_hit_rate(library, classification, subclass = nil)
      data = {labels:[], data:[]}

      # get all decades
      dc = "select distinct FLOOR(publication_year/10)*10 AS decade from shelf_listings where publication_year > 1000 order by decade asc"
      decades = ShelfListing.connection.execute(dc)
      gt = 0

      # setup the joins to get listings without and with interventions
      j_all = "inner join barcodes b on shelf_listings.id = b.shelf_listing_id"
      j_i = "#{j_all} inner join barcode_interventions i on b.id = i.barcode_id"

      # first get the counts for listings with no or invalid pub year
      where_q = "(publication_year is null or publication_year<1000) and active=1"
      if library.downcase != "any"
         where_q << " and library=#{sanitize(library)}"
      end

      # subclass overrides class
      if !subclass.nil? && subclass.downcase != "any"
         where_q << " and subclassification=#{sanitize(subclass)}"
      else
         if classification.downcase != "any"
            where_q << " and classification=#{sanitize(classification)}"
         end
      end

      total = ShelfListing.joins(j_all).where(where_q).distinct.count
      gt += total
      total_i = ShelfListing.joins(j_i).where(where_q).distinct.count

      pct = ((total_i.to_f/total.to_f)*100.0).round(2)
      data[:data] << pct
      data[:labels] << "No Year|#{total}|#{total_i}"

      # Get counts for each decade
      decades.each do |decade|
         y0 = decade[0].to_i
         y1 = y0+9

         where_q = "publication_year>=#{y0} and publication_year<=#{y1} and active=1"
         if library.downcase != "any"
            where_q << " and library=#{sanitize(library)}"
         end
         if !subclass.nil? && subclass.downcase != "any"
            where_q << " and subclassification=#{sanitize(subclass)}"
         else
            if classification.downcase != "any"
               where_q << " and classification=#{sanitize(classification)}"
            end
         end

         total = ShelfListing.joins(j_all).where(where_q).distinct.count
         gt += total
         next if total < 20

         total_i = ShelfListing.joins(j_i).where(where_q).distinct.count
         if total_i > 0
            pct = ((total_i.to_f/total.to_f)*100.0).round(2)
            data[:data] << pct
            data[:labels] << "#{y0}|#{total}|#{total_i}"
         end
      end
      data[:total] = gt
      return data
   end

   private
   def self.sanitize(text)
      return ActiveRecord::Base::connection.quote(text)
   end
end
