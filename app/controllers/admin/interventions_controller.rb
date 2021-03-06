class Admin::InterventionsController < ApplicationController
   def destroy
      i = Intervention.find(params[:id])
      i.barcode_intervention.destroy
      i.details.destroy_all
      i.destroy!
      render plain: "Intervention #{params[:id]} destroyed"
   end

   def create
      bc = Barcode.find(params[:barcode])
      intervention = Intervention.create!(
         special_interest: params[:special_interest], special_problems: params[:special_problems],
         who_found: params[:who_found], found_at: params[:found_at].to_datetime)
      params[:interventions].each do |id|
         InterventionDetail.create(intervention: intervention, intervention_type_id: id.to_i)
      end
      BarcodeIntervention.create(barcode: bc, intervention: intervention)
      redirect_to "/admin/listings/#{params[:listing_id]}"
   end

   def update
      i = Intervention.find(params[:id])
      i.update( update_params )
      if !params[:interventions].blank?
         i.intervention_details.destroy_all
         params[:interventions].each do |id|
            InterventionDetail.create(intervention: i, intervention_type_id: id.to_i)
         end
      end
      redirect_to "/admin/listings/#{params[:listing_id]}"
   end

   def update_params
      params.permit(:found_at, :who_found, :special_problems, :special_interest)
   end
end
