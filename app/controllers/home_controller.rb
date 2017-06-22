class HomeController < ApplicationController
   before_action :show_banner
   skip_before_action :authorize

   def show_banner
      @banner = true
   end

   def index
      clear_session
   end

   def create
      clear_session
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
