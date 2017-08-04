class Admin::DestinationsController < ApplicationController
   def destroy
      d = Destination.find(params[:id])
      d.barcode_destination.destroy
      d.destroy!
      render plain: "Destination #{params[:id]} destroyed"
   end

   def create
      bc = Barcode.find(params[:barcode])
      destination = Destination.create!(destination_name_id: params[:destination_name_id],
         bookplate: params[:bookplate], date_sent_out: params[:date_sent_out] )
      BarcodeDestination.create(barcode: bc, destination: destination)
      redirect_to "/admin/listings/#{params[:listing_id]}"
   end

   def update
      d = Destination.find(params[:id])
      d.update( update_params )
      redirect_to "/admin/listings/#{params[:listing_id]}"
   end

   def update_params
      params.permit(:destination_name_id, :date_sent_out, :bookplate)
   end
end
