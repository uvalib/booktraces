class Api::ApiController < ApplicationController
   skip_before_action :authorize
   # Non-datatables search API. Simple params:
   # q=[global query], l=library, c=class, s=subclass,
   #                   i=interventions[none,any,inscription,annotation,marginalia,insertion,artwork,library]
   # start=start offset, length=how many to return; limit 1000
   def search
      query_terms = []
      start = params[:start]
      start = 0 if start.nil?
      len = params[:length]
      if len.nil?
         len = 100
      else
         len = len.to_i
      end

      lib_filter = params[:l]
      if !lib_filter.blank? && lib_filter != "Any"
         query_terms << "library = '#{lib_filter}'"
      end

      class_filter = params[:c]
      if !class_filter.blank? && class_filter != "Any"
         query_terms << "classification = '#{class_filter}'"
      end

      subclass_filter = params[:s]
      if !subclass_filter.blank? && subclass_filter != "Any"
         query_terms << "subclassification = '#{subclass_filter}'"
      end

      intervention_term = get_intervention_term( params[:i] )
      query_terms << intervention_term if !intervention_term.blank?

      q = params[:q]
      if !q.blank?
         str =  "(internal_id like '%#{q}%' or title regexp '[[:<:]]#{q}[[:>:]]' or call_number like '%#{q}%'"
         str << " or bookplate_text regexp '[[:<:]]#{q}[[:>:]]' or b.barcode like '%#{q}%'"
         if !intervention_term.include?("ALL_LISTINGS") && !intervention_term.include?("NO_INTERVENTIONS")
            str << " or i.special_problems like '%#{q}%'"
            str << " or i.special_interest like '%#{q}%'"
         end
         str << ")"
         query_terms << str
      end
      total, filtered, res  = do_search(query_terms, start, len, "id asc")
      render json: { total: total, filtered: filtered, start: start, length: len, data: res.as_json(except: ["created_at", "updated_at", "who_checked", "id"]) }
   end

   # public API to get listing details. Accepts 1 param; ID which
   # corresponds to internal ID
   def detail
      out = ShelfListing.includes(:interventions).includes(:barcodes).find_by(internal_id: params[:id])
      json = out.as_json(except: ["created_at", "updated_at", "who_checked", "id"])
      json[:barcodes] = out.barcodes.where(active:1).pluck("barcode")
      json[:interventions] = []
      out.interventions.each do |i|
         inv = i.as_json(except: ["who_found", "created_at", "updated_at", "id"])
         inv[:details] = []
         i.details.each do |d|
            inv[:details] << "#{d.category}: #{d.name}"
         end
         json[:interventions] << inv
      end
      dest =  out.destinations.first
      if !dest.nil?
         json[:preservation] = { date_sent_out: dest.date_sent_out, destination: dest.destination_name.name, bookplate: dest.bookplate}
      end
      render json: json
   end

   # POST query request from datatables
   # Key stuff to look for:
   #   params[:search][:value] = 'global' search
   #   params[:columns][5, 6 or 7][:search][:value]
   def query
      draw = params[:draw].to_i
      session[:state] = nil

      query_terms = []

      lib_filter = params[:columns]["5"][:search][:value]
      if !lib_filter.blank? && lib_filter != "Any"
         query_terms << "library = '#{lib_filter}'"
      end

      sys_filter = params[:columns]["6"][:search][:value]
      if !sys_filter.blank? && sys_filter != "Any"
         query_terms << "classification_system = '#{sys_filter}'"
      end

      class_filter = params[:columns]["7"][:search][:value]
      if !class_filter.blank? && class_filter != "Any"
         query_terms << "classification = '#{class_filter}'"
      end

      subclass_filter = params[:columns]["8"][:search][:value]
      if !subclass_filter.blank? && subclass_filter != "Any"
         query_terms << "subclassification = '#{subclass_filter}'"
      end

      intervention_term = get_intervention_term(params[:columns]["9"][:search][:value])
      query_terms << intervention_term if !intervention_term.blank?

      status_filter = params[:columns]["10"][:search][:value]
      if !status_filter.blank? && status_filter != "Any"
         query_terms << "ls.result = '#{status_filter}'"
      end

      q_val = params[:search]["value"]
      if !q_val.blank?
         q = q_val.split("|")[0]
         field = q_val.split("|")[1]
         full = q_val.split("|")[2]
         if field == "all"
            if full == true
               str =  "(internal_id like '%#{q}%' or title regexp '[[:<:]]#{q}[[:>:]]' or call_number like '%#{q}%'"
               str << " or bookplate_text regexp '[[:<:]]#{q}[[:>:]]' or b.barcode like '%#{q}%'"
            else
               str =  "(internal_id like '%#{q}%' or title like '%#{q}%' or call_number like '%#{q}%'"
               str << " or bookplate_text regexp '%#{q}%' or b.barcode like '%#{q}%'"
            end

            if !intervention_term.include?("ALL_LISTINGS") && !intervention_term.include?("NO_INTERVENTIONS")
               if full == true
                  str << " or i.special_problems regexp '%[[:<:]]#{q}[[:>:]]'"
                  str << " or i.special_interest regexp '[[:<:]]#{q}[[:>:]]'"
               else
                  str << " or i.special_problems like '%#{q}%'"
                  str << " or i.special_interest like '%#{q}%'"
               end
            end
            str << ")"
         else
            if full == "true" && (field == 'title' || field == 'bookplate' || field == 'i.special_problems' || field == 'i.special_interest')
               str = "#{field} regexp '[[:<:]]#{q}[[:>:]]'"
            else
               str = "#{field} like '%#{q}%'"
            end
         end
         query_terms << str
      end

      # ordering!
      columns = ["internal_id","b.barcode","call_number","title","bookplate_text",
         "library","classification_system","classification","subclassification"]
      order_info = params[:order]["0"]
      idx = order_info['column'].to_i
      order_str = "#{columns[idx]} #{order_info['dir']}"

      # convert these settings into a structure that datatables can
      # unpack and restore upon page refresh
      session[:search_state] = {
         time: Time.now.to_i, start: params[:start], length: params[:length],
         search: {search: q_val}, columns: [ {}, {}, {}, {}, {},
            {search: {search: lib_filter}}, {search: {search: sys_filter}}, {search: {search: class_filter}},
            {search: {search: subclass_filter}}, {search: {search: params[:columns]["9"][:search][:value]}},
            {search: {search: status_filter}}, {} ]
      }

      total, filtered, res  = do_search(query_terms, params[:start], params[:length], order_str)

      # Format the results in the structure required by datatables
      # Table: ID, BARCODE, CallNum, Title, Bookplate, Library, class, subclass, intervention
      data = []
      res.each do |sl|
         bc = sl.active_barcodes.join(", ")
         flag = !sl.interventions.empty?
         data << [
            sl.internal_id, bc, sl.call_number, sl.title, sl.bookplate_text,
            sl.library, sl.classification_system, sl.classification, sl.subclassification,
            flag, sl.listing_status.result.capitalize, sl.id
         ]
      end

      # note: only set filtered different from total if there is some query made
      resp = { draw: draw, recordsTotal: total, recordsFiltered: filtered, data: data}
      render json: resp
   end

   # Get the last saved search filter state
   def search_state
      render json: session[:search_state]
   end

   def get_intervention_term( intervention_filter )
      return "ALL_LISTINGS" if intervention_filter.downcase == "all"

      intervention_type = intervention_filter.to_i
      term = ""
      # if a specific type of intervention was selected, the filter will be a
      # non-zero number. show only interventions of that type
      if intervention_type > 0
         term = "details.intervention_type_id = #{intervention_type}"
      else
         # for named types of intervention (except none), select by numeric range
         if intervention_filter.downcase == "inscription"
            term = "details.intervention_type_id < 5"
         elsif intervention_filter.downcase == "annotation"
            term = "details.intervention_type_id >= 5 and details.intervention_type_id <= 7"
         elsif intervention_filter.downcase == "marginalia"
            term = "details.intervention_type_id >= 8 and details.intervention_type_id <= 10"
         elsif intervention_filter.downcase == "insertion"
            term = "details.intervention_type_id >= 11 and details.intervention_type_id <= 15"
         elsif intervention_filter.downcase == "artwork"
            term = "details.intervention_type_id >= 16 and details.intervention_type_id <= 17"
         elsif intervention_filter.downcase == "library"
            term = "details.intervention_type_id > 17"
         elsif intervention_filter.downcase == "none"
            term = "NO_INTERVENTIONS"
         end
      end
      return term
   end

   def classifications
      if params[:id].downcase == "any"
         render json: ["Any"] + ShelfListing.all.pluck(:classification).uniq.to_a
      else
         render json: ["Any"] + ShelfListing.where(classification_system: params[:id]).pluck(:classification).uniq.to_a
      end
   end

   def subclassifications
      if params[:id].downcase == "any"
         render json: ["Any"] + ShelfListing.all.pluck(:subclassification).uniq.to_a
      else
         render json: ["Any"] + ShelfListing.where(classification: params[:id]).pluck(:subclassification).uniq.to_a
      end
   end

   def do_search(query_terms, start, len, order_str)

      # build the join query. Barcode is always required. Use initial
      # join to get the total count of listings
      intervention_join = "inner join barcodes b on b.shelf_listing_id = shelf_listings.id"
      intervention_join << " inner join listing_statuses ls on listing_status_id = ls.id"
      total = ShelfListing.joins(intervention_join).where("b.active = 1").distinct.count
      filtered = total

      # in all cases, we only care about ACTIVE barcodes
      query_terms << "b.active = 1"

      if query_terms.include? "ALL_LISTINGS"
         # nothing else required for all. Just remove the flag from the list
         query_terms.delete "ALL_LISTINGS"
      elsif query_terms.include? "NO_INTERVENTIONS"
         # Only take listings with NO interventions (left join where right is null) and remove the flag
         intervention_join << " left join barcode_interventions bi on b.id = bi.barcode_id"
         query_terms.delete "NO_INTERVENTIONS"
         query_terms << "bi.barcode_id is null"
      else
         # intervention type requested. Need all data; barocde, barcode_intervention, intervention and details
         intervention_join << " inner join barcode_interventions bi on bi.barcode_id = b.id"
         intervention_join << " inner join interventions i on i.id = bi.intervention_id"
         intervention_join << " inner join intervention_details details on i.id = details.intervention_id"
      end

      if query_terms.empty?
         filtered = ShelfListing.joins(intervention_join).distinct.count
         res = ShelfListing.joins(intervention_join).distinct.order(order_str).offset(start).limit(len)
      else
         q_str = query_terms.join(" and ")
         filtered = ShelfListing.where(q_str).joins(intervention_join).distinct.count
         res = ShelfListing.joins(intervention_join).where(q_str).distinct
            .order(order_str).offset(start).limit(len)
      end
      return total, filtered, res
   end

   def report
      if params[:type] == "intervention-distribution"
         render json: Report.intervention_distribution and return
      elsif params[:type] == "hit-rate"
         if params[:pool] == "library"
            render json: Report.library_hit_rate and return
         elsif params[:pool] == "classification"
            render json: Report.classification_hit_rate(params[:system]) and return
         elsif params[:pool] == "subclassification"
            render json: Report.subclassification_hit_rate(params[:classification]) and return
         elsif params[:pool] == "top25"
            render json: Report.hit_rate_extremes(:top) and return
         elsif params[:pool] == "bottom25"
            render json: Report.hit_rate_extremes(:bottom) and return
         end
      end
      render plain: "Invalid report type", status: :error
   end
end
