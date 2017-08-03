class ListingsController < ApplicationController
  skip_before_action :authorize
  def index
  end
  def show
     @listing = ShelfListing.find(params[:id])
  end
end
