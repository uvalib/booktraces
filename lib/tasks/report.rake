namespace :report do
   desc "generate authors report"
   task :author  => :environment do
      tc =  "select  author,subclassification,count(sl.id) as cnt from shelf_listings sl"
      tc << " inner join barcodes b on sl.id = b.shelf_listing_id"
      tc << " where author <> '' and author <>'0.0'"
      tc << " group by author order by author asc"
      data = {}
      ShelfListing.connection.execute(tc).each do |sl|
         data[ sl[0] ] =  {subclass: sl[1], holdings: sl[2]}
      end

      ic = "select  author,count(author) as ivcnt from shelf_listings sl"
      ic << " inner join barcodes b on sl.id = b.shelf_listing_id"
      ic << " inner join barcode_interventions i on b.id = i.barcode_id"
      ic << " where author <> '' and author <>'0.0'"
      ic << " group by author order by author asc"
      icnt = 0
      ShelfListing.connection.execute(ic).each do |sl|
         cnt = sl[1]
         data[ sl[0] ][:interventions] = cnt
         if cnt > 2
            icnt+=1
            total = data[ sl[0] ][:holdings]
            pct = ((cnt.to_f / total.to_f) * 100.0).round(2)
            data[ sl[0] ][:percent] = pct
         end
      end

      filtered =  data.select{|key,val| val.has_key?(:percent) }
      filtered = filtered.sort_by {|key,val| val[:percent] }
      filtered.reverse!

      puts "author, subclass, holdings, interventions, percentage"
      filtered.each do |key,val|
         out = "\"#{key}\", #{val[:subclass]}, #{val[:holdings]}, #{val[:interventions]}, #{val[:percent]}"
         puts out
      end
   end

   desc "lookup catalog key"
   task :lookup  => :environment do
      wsls_csv = File.join(Rails.root, "booktraces_lookups.csv")
      puts "internal_id, call_number"
      cnt =0
      CSV.foreach(wsls_csv, headers: true) do |row|
         cnt += 1
         internal_id = row[7]
         sl = ShelfListing.find_by(internal_id: internal_id)
         puts "#{internal_id}, #{sl.call_number}"
      end
      puts "DONE... got #{cnt} items"
   end
end
