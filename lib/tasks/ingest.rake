require 'csv'

namespace :ingest do
   desc "Ingest ALL"
   task :all  => :environment do
      ivy = "listings/Ivy-Stacks-sample-shelf-list.csv"
      files = [
         "Alderman-subclass-B-shelf-list.csv", "Clemons.csv", "Law.csv",
         "Alderman.csv", "Ivy-Annex.csv", "Music-books.csv", "BSEL.csv",
         "Music-scores.csv"]
      files.sort!
      base = ENV['base']
      abort("base is required") if base.nil?

      files.each do |f|
         puts "INGEST #{f}"
         ENV['file'] = File.join(base, "listings", f)
         Rake::Task['ingest:listing'].execute
      end

      ENV['file'] = File.join(base,ivy)
      Rake::Task['ingest:ivy'].execute
   end

   desc "Ingest a cataloging .csv file"
   task :cataloging  => :environment do
      file = ENV["file"]
      abort("file is required") if file.nil?
      puts "Ingesting cataloging file #{file}"
      cnt = 0
      x=0
      CSV.foreach(file, headers: true) do |row|
         # FORMAT:
         # 0=internal_id, 1=original item id, 2=item id on book, 3=date sent out.
         # 4=problem, 5=date returned, 6=updated id, 7=destination

         # First to match on internal ID
         sl = ShelfListing.find_by(internal_id: row[0])
         if sl.nil?
            puts "Unable to find listing for #{row[0]}"
            next
         end

         # pull and normalize the item id on book and updated id fields
         book_item_id = row[2].strip.upcase
         updated_id = row[6].strip.upcase

         sent_out = nil
         returned = nil
         begin
            sent_out = row[3].strip.to_date
         rescue Exception=>e
         end
         begin
            returned = row[5].strip.to_date
         rescue Exception=>e
         end
         cr = CatalogingRequest.create!(
            shelf_listing_id: sl.id, sent_out_on: sent_out,
            returned_on: returned, destination: row[7])

         # mark the original barcode for this listing as inactive
         # and add the newly updated one
         Barcode.where("shelf_listing_id = #{sl.id} and cataloging_request_id is null and active=1").update_all(active: false)
         Barcode.create(barcode: updated_id, shelf_listing_id: sl.id, cataloging_request_id: cr.id)

         # Problems are a semicolon separated list. Parse and create problems records
         # for each and link to the request
         if !row[4].blank?
            row[4].split(";").each do |a|
               Problem.create!(name: a.strip, cataloging_request: cr)
            end
         end
         print "."
      end
   end

   desc "Ingest a Shelf Listing .csv file"
   task :listing  => :environment do
      file = ENV["file"]
      abort("file is required") if file.nil?
      puts "Ingesting contents of #{file}"

      statuses = BookStatus.all

      ids = []
      CSV.foreach(file, headers: true) do |row|
         print "."

         # FORMAT:
         # 0=File, 1=Title, 2=Call Number, 3=Stacks Item ID, 4=ID match?,
         # 5=Bookplate Text, 6=Action, 7=Date checked, 8=Who checked,
         # 9=Index, 10=Item ID, 11=location, 12=Library, 13=Class, 14=Subclass
         # ... and Law.csv includes a 15th column for classification system
         stacks_item_id = row[3].strip.upcase if !row[3].blank?
         original_item_id = row[10].strip.upcase
         statuses, status = find_status(statuses, "valid")

         # Is this a record with some sort of problem with the exported id vs actual shelved id?
         if row[4].strip.downcase == 'false' || stacks_item_id.downcase == "no barcode"
            if stacks_item_id.blank?
               puts "WARN Encountered blank shelf item ID for #{row[9]}. Skipping"
               next
            elsif stacks_item_id[0] == "X"  # barcodes start with an 'X'
               if stacks_item_id == original_item_id
                  statuses, status = find_status(statuses, "valid")
               else
                  statuses, status = find_status(statuses, "barcode mismatch")
               end
            elsif stacks_item_id[0...2] == "35"   # Law ueses a long numeric item id that starts with 35
               if stacks_item_id == original_item_id
                  statuses, status = find_status(statuses, "valid")
               else
                  statuses, status = find_status(statuses, "barcode mismatch")
               end
            elsif stacks_item_id.downcase == "no barcode"
               statuses, status = find_status(statuses, "no barcode")
               stacks_item_id = nil
            else
               status_string = stacks_item_id.downcase.gsub(/\s+/, " ")
               statuses, status = find_status(statuses, status_string)
               stacks_item_id = nil
            end
         end

         if ids.include? original_item_id
            puts "WARN Found duplicate Item ID #{original_item_id} for #{row[9]}"
         else
            ids << original_item_id
         end

         sl = ShelfListing.create!(title: row[1], call_number: row[2],
            original_item_id: original_item_id, book_status: status,
            bookplate_text: row[5], date_checked: row[7], who_checked: row[8],
            internal_id: row[9].strip, location: row[11].strip, library: row[12].strip,
            classification: row[13].strip, subclassification:  row[14].strip )

         # If there is a valid barcode for this book, add it to the barcodes table
         if !stacks_item_id.nil?
            Barcode.create!(shelf_listing_id: sl.id, barcode: stacks_item_id)
         end

         if file.include? "Law.csv"
            sl.update(classification_system: row[15].strip )
         end

         # Actions are a semicolon separated list. Parse and create action records
         # for each and link to the ShelfListing
         if !row[6].blank?
            row[6].split(";").each do |a|
               Action.create(name: a.strip, shelf_listing: sl)
            end
         end
      end
      puts "DONE"
   end

   desc "Ingest a Shelf Listing IVY STACKS"
   task :ivy  => :environment do
      file = ENV["file"]
      abort("file is required") if file.nil?
      puts "Ingesting contents of #{file}"

      valid_status = BookStatus.first

      ids = []
      seq = 1
      CSV.foreach(file, headers: true) do |row|
         print "."

         # FORMAT:
         # 0=File, 1=Call Number, 2=Item ID, 3=current location
         # 4=Pub Year, 5=Author, 6=Title, 7=260 field,
         # 8=Shelving Key, 9=Library, 10=Class, 11=Subclass
         item_id = row[2].strip.upcase
         if ids.include? item_id
            puts "WARN Found duplicate Item ID #{item_id}"
         else
            ids << item_id
         end

         pub_year = row[4].split(".")[0]
         sl = ShelfListing.create!(title: row[6], call_number: row[1],
            original_item_id: item_id, book_status: valid_status,
            author: row[5], publication_year: pub_year,
            internal_id: "IS-%05d" % seq, location: row[3].strip, library: row[9].strip,
            classification: row[10].strip, subclassification:  row[11].strip )
         Barcode.create!(shelf_listing_id: sl.id, barcode: item_id)
         seq += 1
      end
      puts "DONE"
   end

   def find_status(statuses, status_txt)
      status_txt = "duplicate" if status_txt == "duplicate listing" || status_txt == "double listing"
      status_txt = "cataloging problem" if status_txt == "cataloging error"
      status_txt "too late" if status_txt == "date too late"
      match = nil
      statuses.each do |s|
         if s.name == status_txt
            match = s
            break
         end
      end
      if match.nil?
         match = BookStatus.create(name: status_txt)
         statuses = BookStatus.all
      end
      return statuses, match
   end
end
