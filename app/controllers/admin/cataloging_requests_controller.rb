class Admin::CatalogingRequestsController < ApplicationController
   def destroy
      c = CatalogingRequest.find(params[:id])
      c.barcode.destroy! if !c.barcode.nil?
      c.reload # reload model to reflect change in barcode list

      # don't leave the listing in a state where it has only an inactive barcode
      if c.shelf_listing.barcodes.count == 1
         c.shelf_listing.barcodes.first.update(active: 1)
      end
      c.destroy!
      render plain: "Catalog request #{params[:id]} destroyed"
   end

   def create
      c = CatalogingRequest.create!( shelf_listing_id: params[:listing_id], sent_out_on: params[:sent_out_on],
         returned_on: params[:returned_on], destination: params[:destination], problems: params[:problems] )
      Barcode.where("shelf_listing_id = #{c.shelf_listing_id} and cataloging_request_id is null and active=1").update_all(active: false)
      Barcode.create(barcode: params[:barcode], shelf_listing_id: params[:listing_id], cataloging_request_id: c.id, origin: "cataloging_request")
      redirect_to "/admin/listings/#{params[:listing_id]}"
   end

   def update
      c = CatalogingRequest.find(params[:id])
      c.update( update_params )
      if (params[:barcode])
         c.barcode.update(barcode: params[:barcode])
      end
      redirect_to "/admin/listings/#{params[:listing_id]}"
   end

   def update_params
      params.permit(:sent_out_on, :returned_on, :destination, :problems)
   end
end
