class UnauthorizedController < ApplicationController
   before_action :show_banner
   skip_before_action :authorize

   def show_banner
      @banner = true
      session[:user] = nil
      session[:user_type] = nil
   end
   
   def index
   end
end
