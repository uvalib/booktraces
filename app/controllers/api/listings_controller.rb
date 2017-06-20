class Api::ListingsController < Api::ApiController
   # POST query request from datatables
   # Key stuff to look for:
   #   params[:search][:value] = 'global' search
   #   params[:columns][5, 6 or 7][:search][:value]
   def query
      draw = params[:draw].to_i
      total = ShelfListing.count
      filtered = total

      query_terms = []
      q = params[:search]["value"]
      if !q.blank?
         query_terms << "(title like '%#{q}%' or call_number like '%#{q}%' or bookplate_text like '%#{q}%')"
      end
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

      # Table: ID, BARCODE, CallNum, Title, Bookplate, Library, class, subclass, intervention
      data = []
      if query_terms.empty?
         res = ShelfListing.includes(:barcodes).includes(:interventions).offset(params[:start]).limit(params[:length])
      else
         q_str = query_terms.join(" and ")
         filtered = ShelfListing.where(q_str).count
         res = ShelfListing.includes(:barcodes).includes(:interventions).where(q_str).offset(params[:start]).limit(params[:length])
      end

      res.each do |sl|
         bc = sl.active_barcodes.join(",")
         flag = !sl.interventions.empty?
         data << [
            sl.internal_id, bc, sl.call_number, sl.title, sl.bookplate_text,
            sl.library, sl.classification, sl.subclassification, flag
         ]
      end

      # note: only set filtered different from total if there is some query made
      resp = { draw: draw, recordsTotal: total, recordsFiltered: filtered, data: data}
      render json: resp
   end
end
