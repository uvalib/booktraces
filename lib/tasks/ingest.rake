require 'csv'

namespace :ingest do

   desc "Fix origin for catalog request"
   task :test  => :environment do
      ShelfListing.all.find_each do |sl|
         if sl.interventions.count > 1
            puts "SL #{sl.id} has #{sl.interventions.count} interventions"
         end
         if sl.destinations.count > 1
            puts "SL #{sl.id} has #{sl.destinations.count} destinations"
         end
      end
   end

   desc "Fix origin for catalog request"
   task :fix_origin  => :environment do
      Barcode.where("cataloging_request_id is not null and active=1").update(origin: "cataloging_request")
   end

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

      row_num = 0
      err_cnt = 0
      mul_cnt = 0
      no_iv = 0
      CSV.foreach(file, headers: true) do |row|
         # FORMAT:
         # 0=barcode, 1=timestamp, 2=user, 3=inscriptions
         # 4=annotations, 5=marginalia, 6=JUNK, 7=insertions
         # 8=artwork, 9=special_interest, 10=special_problems,
         # 11=library_markings

         #print "."
         # FIRST, see if the barcode exists:
         row_num += 1
         bc_str = row[0].strip.upcase

         if row[3].blank? && row[4].blank? &&row[5].blank? &&
            row[7].blank? && row[8].blank? && row[11].blank?
            puts "SKIPPING: No interventions barcode #{bc_str}"
            no_iv += 1
            next
         end

         if Barcode.where(barcode: bc_str, active: 1).count == 0
            puts "ERROR: Couldn't find barcode #{bc_str} for #{row_num}; creating placeholder"
            err_cnt += 1
            Barcode.create(barcode: bc_str)
         end

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
      puts "DONE, total rows processed #{row_num}"
      puts "Error count #{err_cnt}, no intervention cnt #{no_iv}"
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

      row_num = 0
      err_cnt = 0
      no_iv = 0
      CSV.foreach(file, headers: true) do |row|
         # FORMAT:
         # 0=timestamp, 1=user, 2=barcode, 3=bookplate,
         # 4=actions, 5=inscriptions, 6=marginalia,
         # 7=annotations, 8=insertions, 9=artwork,
         # 10=library_markings, 11=special_interest, 12=special_problems

         #print "."
         # FIRST, see if the barcode exists:
         row_num += 1
         bc_str = row[2].strip.upcase

         if row[5].blank? && row[6].blank? &&row[7].blank? &&
            row[8].blank? && row[9].blank? && row[10].blank?
            puts "SKIPPING: No interventions barcode #{bc_str}"
            no_iv += 1
            next
         end

         if Barcode.where(barcode: bc_str, active: 1).count == 0
            puts "ERROR: Couldn't find barcode #{bc_str}; creating placeholder"
            err_cnt += 1
            Barcode.create(barcode: bc_str)
         end

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
         end
      end
      puts "DONE, total rows processed #{row_num}"
      puts "Error count #{err_cnt}, no intervention #{no_iv}"
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

         problems = nil
         if !row[4].blank?
            problems = row[4].split(";").map(&:capitalize).join(', ')
         end
         cr = CatalogingRequest.create!(
            shelf_listing_id: sl.id, sent_out_on: sent_out,
            returned_on: returned, destination: row[dest_idx], problems: row[4])

         # If there is no matching barcode for this book, create one
         if sl.barcodes.where(barcode: updated_id).count == 0
            # mark the original barcode for this listing as inactive and add the new one
            Barcode.where("shelf_listing_id = #{sl.id} and cataloging_request_id is null and active=1").update_all(active: false)
            Barcode.create(barcode: updated_id, shelf_listing_id: sl.id, cataloging_request_id: cr.id, origin: "cataloging_request")
         end

         print "."
      end
   end

   desc "Ingest a Shelf Listing .csv file"
   task :listing  => :environment do
      file = ENV["file"]
      abort("file is required") if file.nil?
      puts "Ingesting contents of #{file}"

      ids = []
      CSV.foreach(file, headers: true) do |row|
         print "."

         # FORMAT:
         # 0=File, 1=Title, 2=Call Number, 3=Stacks Item ID, 4=ID match?,
         # 5=Bookplate Text, 6=Action, 7=Date checked, 8=Who checked,
         # 9=Index, 10=Item ID, 11=location, 12=Library, 13=Class, 14=Subclass
         # ... and Law.csv includes a 15th column for classification system
         stacks_item_id = row[3].strip.upcase if !row[3].blank?
         item_id = row[10].strip.upcase
         status="valid"

         # Is this a record with some sort of problem with the exported id vs actual shelved id?
         if row[4].strip.downcase == 'false' || stacks_item_id.downcase == "no barcode"
            if stacks_item_id.blank?
               puts "WARN Encountered blank shelf item ID for #{row[9]}. Skipping"
               next
            elsif stacks_item_id[0] == "X"  # barcodes start with an 'X'
               if stacks_item_id != item_id
                  status = "barcode mismatch"
               end
            elsif stacks_item_id[0...2] == "35"
               # Law uses a long numeric item id that starts with 35
               if stacks_item_id != item_id
                  status = "barcode mismatch"
               end
            elsif stacks_item_id.downcase == "no barcode"
               status = "no barcode"
               stacks_item_id = nil
            else
               status = stacks_item_id.downcase.gsub(/\s+/, " ")
               stacks_item_id = nil
            end
         end

         if ids.include? item_id
            puts "WARN Found duplicate Item ID #{item_id} for #{row[9]}"
         else
            ids << item_id
         end

         # Actions are a semicolon separated list; parse
         acts = row[6].split(";")
         ls = ListingStatus.create(date_checked: row[7], who_checked: row[8], result: status, actions: acts.join(", "))
         sl = ShelfListing.create!(title: row[1], call_number: row[2],
            bookplate_text: row[5], listing_status: ls,
            internal_id: row[9].strip, location: row[11].strip,
            library: row[12].strip, classification: row[13].strip, subclassification:  row[14].strip )

         # Create brarcode records for this listing; the original item ID
         # and the id that was found on the shelf
         Barcode.create!(shelf_listing_id: sl.id, barcode: item_id, origin: "sirsi")
         if !stacks_item_id.blank?
            # non-blank stacks item id trumps original
            Barcode.where(shelf_listing_id: sl.id).update_all(active: 0)
            Barcode.create!(shelf_listing_id: sl.id, barcode: stacks_item_id, origin: "stacks")
         end

         if file.include? "Law.csv"
            sl.update(classification_system: row[15].strip )
         end
      end
      puts "DONE"
   end

   desc "Ingest a Shelf Listing IVY STACKS"
   task :ivy  => :environment do
      file = ENV["file"]
      abort("file is required") if file.nil?
      puts "Ingesting contents of #{file}"

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
         ls = ListingStatus.create( result: "valid" )
         sl = ShelfListing.create!(title: row[6], call_number: row[1],
            listing_stats: ls,
            author: row[5], publication_year: pub_year,
            internal_id: "IS-%05d" % seq, location: row[3].strip, library: row[9].strip,
            classification: row[10].strip, subclassification:  row[11].strip )
         Barcode.create!(shelf_listing_id: sl.id, barcode: item_id, origin: "stacks")
         seq += 1
      end
      puts "DONE"
   end
end
