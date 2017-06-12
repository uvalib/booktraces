require 'csv'

namespace :ingest do

   desc "Ingest ALL data; listings, cataloging, interventions and destinations"
   task :all  => :environment do
      ivy = "listings/Ivy-Stacks-sample-shelf-list.csv"
      listings = [
         "Alderman-subclass-B-shelf-list.csv", "Clemons.csv", "Law.csv",
         "Alderman.csv", "Ivy-Annex.csv", "Music-books.csv", "BSEL.csv",
         "Music-scores.csv"]
      listings.sort!
      base = ENV['base']
      abort("base is required") if base.nil?

      listings.each do |f|
         puts "INGEST #{f}"
         ENV['file'] = File.join(base, "listings", f)
         Rake::Task['ingest:listing'].execute
      end

      ENV['file'] = File.join(base,ivy)
      Rake::Task['ingest:ivy'].execute

      # Cataloging ========================================
      catalogs = ["cataloging.csv", "BSEL books sent to cataloging.csv"]
      catalogs.each do |f|
         puts "CATALOGING INGEST #{f}"
         ENV['file'] = File.join(base, "cataloging", f)
         Rake::Task['ingest:cataloging'].execute
      end

      # Interventions =====================================
      ENV['file'] = File.join(base, "interventions", "intervention-data-except-Ivy-Stacks.csv")
      Rake::Task['ingest:interventions'].execute
      ENV['file'] = File.join(base, "interventions", "Ivy-Stacks-intervention-data-with-bookplates-and-actions.csv")
      Rake::Task['ingest:ivy_interventions'].execute

      # Destinations ======================================
      dests = ["preservation.csv", "BSEL books sent to preservation.csv",
         "Special-Collections.csv", "BSEL-books-sent-to-special-collections-for-bookplates.csv"]
      dests.each do |f|
         puts "DESTINATION INGEST #{f}"
         ENV['file'] = File.join(base, "destinations", f)
         Rake::Task['ingest:destinations'].execute
      end
   end

   desc "Ingest destinaton data (non-special-collection)"
   task :destinations  => :environment do
      file = ENV["file"]
      abort("file is required") if file.nil?
      puts "Ingesting destinations file #{file}"
      names = DestinationName.all

      sc = file.downcase.include? "special"

      CSV.foreach(file, headers: true) do |row|
         # FORMAT:
         # 0=barcode, 1=destination, 2=date sent
         # Notes: date is like 2017-03-23T00:00:00Z or text description
         #        strip the T00:00:00Z part
         # -- OR for special collections --
         # 0=bookplate, 1=barcode, 2=date sent

         print "."
         date = row[2].gsub /T00:00:00Z/,''
         if sc
            destination = Destination.create!(destination_name_id: 3, date_sent_out: date, bookplate: row[0])
            bc_str = row[1].strip.upcase
         else
            dn = names.select { |n| n.name.downcase == row[1].strip.downcase }
            dn = dn.first
            destination = Destination.create!(destination_name: dn, date_sent_out: date)
            bc_str = row[0].strip.upcase
         end

         Barcode.where(barcode: bc_str, active: 1).each do |bc|
            BarcodeDestination.create(barcode: bc, destination: destination)
         end
      end
   end

   desc "Ingest non-ivy interventions"
   task :interventions  => :environment do
      file = ENV["file"]
      abort("file is required") if file.nil?
      puts "Ingesting interventions file #{file}"
      types= InterventionType.all

      CSV.foreach(file, headers: true) do |row|
         # FORMAT:
         # 0=barcode, 1=timestamp, 2=user, 3=inscriptions
         # 4=annotations, 5=marginalia, 6=JUNK, 7=insertions
         # 8=artwork, 9=special_interest, 10=special_problems,
         # 11=library_markings

         print "."
         intervention = Intervention.create!(
            special_interest: row[9], special_problems: row[10],
            who_found: row[2], found_at: row[1].to_datetime)

         if !row[3].blank?
            add_intervention_detail( intervention, "inscription", row[3].strip.downcase, types )
         end
         if !row[4].blank?
            add_intervention_detail( intervention, "annotation", row[4].strip.downcase, types )
         end
         if !row[5].blank?
            add_intervention_detail( intervention, "marginalia", row[5].strip.downcase, types )
         end
         if !row[7].blank?
            add_intervention_detail( intervention, "insertion", row[7].strip.downcase, types )
         end
         if !row[8].blank?
            if row[8].downcase.include? "juvenile"
               InterventionDetail.create(intervention: intervention, intervention_type_id: 17)
            else
               InterventionDetail.create(intervention: intervention, intervention_type_id: 16)
            end
         end
         if !row[11].blank?
            add_intervention_detail( intervention, "library", row[11].strip.downcase, types )
         end

         bc_str = row[0].strip.upcase
         Barcode.where(barcode: bc_str, active: 1).each do |bc|
            BarcodeIntervention.create(barcode: bc, intervention: intervention)
         end
      end
   end

   def add_intervention_detail(intervention, category, vals, types)
      vals.split(",").each do |val|
         d=nil
         types.where(category: category).each do |t|
            if /\b#{t.name}\b/.match(val)
               d = InterventionDetail.create(intervention: intervention, intervention_type: t)
               break
            end
         end
         if d.nil?
            puts "ERROR Unknown intervention type #{val}"
         end
      end
   end

   desc "Ingest ivy interventions"
   task :ivy_interventions  => :environment do
      file = ENV["file"]
      abort("file is required") if file.nil?
      puts "Ingesting IVY interventions file #{file}"
      types = InterventionType.all

      CSV.foreach(file, headers: true) do |row|
         # FORMAT:
         # 0=timestamp, 1=user, 2=barcode, 3=bookplate,
         # 4=actions, 5=inscriptions, 6=marginalia,
         # 7=annotations, 8=insertions, 9=artwork,
         # 10=library_markings, 11=special_interest, 12=special_problems

         print "."
         intervention = Intervention.create!(
            special_interest: row[11], special_problems: row[12],
            who_found: row[1], found_at: row[0].to_datetime)

         if !row[5].blank?
            add_intervention_detail( intervention, "inscription", row[5].strip.downcase, types )
         end
         if !row[7].blank?
            add_intervention_detail( intervention, "annotation", row[7].strip.downcase, types )
         end
         if !row[6].blank?
            add_intervention_detail( intervention, "marginalia", row[6].strip.downcase, types )
         end
         if !row[8].blank?
            add_intervention_detail( intervention, "insertion", row[8].strip.downcase, types )
         end
         if !row[9].blank?
            if row[9].downcase.include? "juvenile"
               InterventionDetail.create(intervention: intervention, intervention_type_id: 17)
            else
               InterventionDetail.create(intervention: intervention, intervention_type_id: 16)
            end
         end
         if !row[10].blank?
            add_intervention_detail( intervention, "library", row[10].strip.downcase, types )
         end

         bc_str = row[2].strip.upcase
         Barcode.where(barcode: bc_str, active: 1).each do |bc|
            BarcodeIntervention.create(barcode: bc, intervention: intervention)

            # backfill bookplate data in original shelf listing
            if bc.shelf_listing.bookplate_text.blank? && !row[3].blank?
               bc.shelf_listing.update(bookplate_text: row[3])
               if !row[4].blank?
                  row[4].split(";").each do |a|
                     act = a.strip.downcase
                     next if act == "none of the above" || act.include?("describe below")
                     if act.include? "too late"
                        Action.create(name: "too late", shelf_listing: bc.shelf_listing)
                     else
                        Action.create(name: act, shelf_listing: bc.shelf_listing)
                     end
                  end
               end
            end
         end
      end
   end

   desc "Ingest a cataloging .csv file"
   task :cataloging  => :environment do
      file = ENV["file"]
      abort("file is required") if file.nil?
      puts "Ingesting cataloging file #{file}"
      date_return_idx = 5
      new_id_idx = 6
      dest_idx = 7
      if file.include? "BSEL"
         date_return_idx = 6
         new_id_idx = 7
         dest_idx = 5
      end
      CSV.foreach(file, headers: true) do |row|
         # FORMAT:
         # 0=internal_id, 1=original item id, 2=item id on book, 3=date sent out.
         # 4=problem, 5=date returned, 6=updated id, 7=destination
         # NOTE: In BSEL catalog data, 5 is destination and the rest are pushed up

         # First to match on internal ID
         sl = ShelfListing.find_by(internal_id: row[0])
         if sl.nil?
            puts "Unable to find listing for #{row[0]}"
            next
         end

         # pull and normalize the updated id field
         updated_id = row[new_id_idx].strip.upcase if !row[new_id_idx].blank?

         sent_out = nil
         returned = nil
         begin
            sent_out = row[3].strip.to_date
         rescue Exception=>e
         end
         begin
            returned = row[date_return_idx].strip.to_date
         rescue Exception=>e
         end
         cr = CatalogingRequest.create!(
            shelf_listing_id: sl.id, sent_out_on: sent_out,
            returned_on: returned, destination: row[dest_idx])

         # If there is no matching barcode for this book, create one
         if sl.barcodes.where(barcode: updated_id).count == 0
            # mark the original barcode for this listing as inactive and add the new one
            Barcode.where("shelf_listing_id = #{sl.id} and cataloging_request_id is null and active=1").update_all(active: false)
            Barcode.create(barcode: updated_id, shelf_listing_id: sl.id, cataloging_request_id: cr.id)
         end

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
