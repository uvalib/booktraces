class HomeController < ApplicationController
   before_action :show_banner
   skip_before_action :authorize

   def show_banner
      @banner = true
      session[:user] = nil
      session[:user_type] = nil
   end

   def index
   end

   def create
      render "/" and return if params[:is_uva].nil?
      session[:user] = nil
      if params[:is_uva] == "no"
         session[:user_type] = :guest
         redirect_to "/listings"
      else
         session[:user_type] = :staff
         redirect_to "/admin/listings"
      end
   end
end
