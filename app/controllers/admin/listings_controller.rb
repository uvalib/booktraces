class Admin::ListingsController < ApplicationController
   def show
      @listing = ShelfListing.find(params[:id])
   end

   def update
      sl = ShelfListing.find(params[:id])

      if params[:update_type] == "status"
         sl.listing_status.update( status_params)
      elsif params[:update_type] == "general"
         sl.update( general_params)
         item_id = sl.barcodes.find_by(origin: "sirsi")
         item_id.update(barcode: params[:item_id]) if item_id.barcode != params[:item_id]
         if !params[:barcodes].nil?
            sl.barcodes.where(active: 1).destroy_all
            params[:barcodes].split(",").each do |bc|
               Barcode.create(barcode: bc.strip, shelf_listing_id: sl.id, origin: "user_edit")
            end
         end
      end

      redirect_to action: "show", id: params[:id]
   end

   def status_params
      params.permit(:who_checked, :date_checked, :result, :actions)
   end

   def general_params
      params.permit(:title, :call_number, :bookplate_text, :author, :publication_year, :library,
         :classification_system, :classification, :subclassification, :location)
   end
end
