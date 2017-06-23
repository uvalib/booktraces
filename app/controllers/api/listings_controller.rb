class Api::ListingsController < Api::ApiController
   # Non-datatables search API. Simple params:
   # q=[global query], l=library, c=class, s=subclass, i=0/1 interventions
   # start=start offset, length=how many to return; limit 1000
   def search
      query_terms = []
      start = params[:start]
      start = 0 if start.nil?
      len = params[:length]
      len = 100 if len.nil?
      if len > 1000
         render text: "Cannot request more than 1000 records", status: :bad_request
         return
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

      interventions = params[:i] == "true"

      q = params[:q]
      if !q.blank?
         str =  "(internal_id like '%#{q}%' or title like '%#{q}%' or call_number like '%#{q}%'"
         str << " or bookplate_text like '%#{q}%' or barcodes.barcode like '%#{q}%'"
         if interventions
            str << " or interventions.special_problems like '%#{q}%'"
            str << " or interventions.special_interest like '%#{q}%'"
         end
         str << ")"
         query_terms << str
      end
      total, filtered, res  = do_search(query_terms, interventions, params[:start], params[:length])
      render json: { total: total, filtered: filtered, data: res.as_json(except: ["created_at", "updated_at", "who_checked", "id"]) }
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
      json[:preservation] = { date_sent_out: dest.date_sent_out, destination: dest.destination_name.name, bookplate: dest.bookplate}
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

      class_filter = params[:columns]["6"][:search][:value]
      if !class_filter.blank? && class_filter != "Any"
         query_terms << "classification = '#{class_filter}'"
      end

      subclass_filter = params[:columns]["7"][:search][:value]
      if !subclass_filter.blank? && subclass_filter != "Any"
         query_terms << "subclassification = '#{subclass_filter}'"
      end

      interventions = params[:columns]["8"][:search][:value] == "true"

      q = params[:search]["value"]
      if !q.blank?
         str =  "(internal_id like '%#{q}%' or title like '%#{q}%' or call_number like '%#{q}%'"
         str << " or bookplate_text like '%#{q}%' or barcodes.barcode like '%#{q}%'"
         if interventions
            str << " or interventions.special_problems like '%#{q}%'"
            str << " or interventions.special_interest like '%#{q}%'"
         end
         str << ")"
         query_terms << str
      end

      # convert these settings into a structure that datatables can
      # unpack and restore upon page refresh
      session[:search_state] = {
         time: Time.now.to_i, start: params[:start], length: params[:length],
         search: {search: q}, columns: [ {}, {}, {}, {}, {},
            {search: {search: lib_filter}}, {search: {search: class_filter}},
            {search: {search: subclass_filter}}, {search: {search: params[:columns]["8"][:search][:value]}},
            {} ]
      }

      total, filtered, res  = do_search(query_terms, interventions, params[:start], params[:length])

      # Format the results in the structure required by datatables
      # Table: ID, BARCODE, CallNum, Title, Bookplate, Library, class, subclass, intervention
      data = []
      res.each do |sl|
         bc = sl.active_barcodes.join(", ")
         flag = !sl.interventions.empty?
         data << [
            sl.internal_id, bc, sl.call_number, sl.title, sl.bookplate_text,
            sl.library, sl.classification, sl.subclassification, flag, sl.id
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

   def do_search(query_terms, interventions, start, len)
      total = ShelfListing.count
      filtered = total

      if query_terms.empty?
         # if interventions, only return listings that join with intervention table
         if interventions
            filtered = ShelfListing.joins(:interventions).count
            res = ShelfListing.joins(:interventions).order(id: :asc).offset(start).limit(len)
         else
            res = ShelfListing.offset(start).limit(len).order(id: :asc)
         end
      else
         q_str = query_terms.join(" and ")
         if interventions
            filtered = ShelfListing.where(q_str).joins(:interventions).count
            res = ShelfListing.joins(:interventions).where(q_str).order(id: :asc).offset(start).limit(len)
         else
            filtered = ShelfListing.joins(:barcodes).where(q_str).count
            res = ShelfListing.joins(:barcodes).where(q_str).order(id: :asc).offset(start).limit(len)
         end
      end
      return total, filtered, res
   end
end
