class Admin::CatalogingRequestsController < ApplicationController
   def destroy
      c = CatalogingRequest.find(params[:id])
      c.barcode.destroy!
      c.reload # reload model to reflect change in barcode list

      # don't leave the listing in a state where it has only an inactive barcode
      if c.shelf_listing.barcodes.count == 1
         c.shelf_listing.barcodes.first.update(active: 1)
      end
      c.problems.destroy_all
      c.destroy!
      render plain: "Catalog request #{params[:id]} destroyed"
   end

   def create
      # bc = Barcode.find(params[:barcode])
      # destination = Destination.create!(destination_name_id: params[:destination_name_id],
      #    bookplate: params[:bookplate], date_sent_out: params[:date_sent_out] )
      # BarcodeDestination.create(barcode: bc, destination: destination)
      # redirect_to "/admin/listings/#{params[:listing_id]}"
   end

   def update
      # d = Destination.find(params[:id])
      # d.update( update_params )
      # redirect_to "/admin/listings/#{params[:listing_id]}"
   end

   def update_params
      params.permit(:destination_name_id, :date_sent_out, :bookplate)
   end
end
