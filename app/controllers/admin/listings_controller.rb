class Admin::ListingsController < ApplicationController
   def show
      @listing = ShelfListing.find(params[:id])
   end
end
