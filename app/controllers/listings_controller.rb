class ListingsController < ApplicationController
  def index
  end
  def show
     @listing = ShelfListing.find(params[:id])
  end
end
