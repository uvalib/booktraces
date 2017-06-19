class Api::ListingsController < ApplicationController
   # POST query request from datatables
   def query

      draw = params[:draw].to_i
      total = ShelfListing.count
      data = []
      # Table: ID, BARCODE, CallNum, Title, Bookplate, Library, class, subclass, intervention
      ShelfListing.offset(params[:start]).limit(params[:length]).includes(:barcodes).includes(:interventions).each do |sl|
         bc = sl.active_barcodes.join(",")
         flag = !sl.interventions.empty?
         data << [
            sl.internal_id, bc, sl.call_number, sl.title, sl.bookplate_text,
            sl.library, sl.classification, sl.subclassification, flag
         ]
      end

      # note: only set filtered different from total if there is some query made
      resp = { draw: draw, recordsTotal: total, recordsFiltered: total, data: data}
      render json: resp
   end
end
