class Admin::ListingsController < ApplicationController
   def show
      @listing = ShelfListing.find(params[:id])
      puts "LISTING ACTIONS =============== #{@listing.actions.join(",")}"
   end

   def update
      @listing = ShelfListing.find(params[:id])

      if params[:update_type] == "status"
         @listing.actions.destroy_all()

         params[:actions].split(",").each do |a|
            Action.create(name: a.strip, shelf_listing: @listing)
         end

         bs = BookStatus.find_by(name: params[:book_status])
         @listing.update(who_checked: params[:who_checked], date_checked: params[:date_checked],
            book_status: bs)
      end

      redirect_to action: "show", id: params[:id]
   end
end
