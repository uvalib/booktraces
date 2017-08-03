class Admin::InterventionsController < ApplicationController
   def destroy
      i = Intervention.find(params[:id])
      i.barcode_intervention.destroy
      i.details.destroy_all
      i.destroy!
      render plain: "Intervention #{params[:id]} destroyed"
   end

   def create
   end

   def update
   end
end
