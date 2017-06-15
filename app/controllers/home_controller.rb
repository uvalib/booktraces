class HomeController < ApplicationController
   before_action :show_banner
   def show_banner
      @banner = true
   end

   def index
   end
end
