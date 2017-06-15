class ApplicationController < ActionController::Base
   protect_from_forgery with: :exception
   helper_method :current_user

   before_action :authorize

   def current_user
      return @curr_user
   end

   def authorize
      if session[:user_type] == "staff"
         computing_id = request.env['HTTP_REMOTE_USER'].to_s
         # if computing_id.blank? && Rails.env != "production"
         #    computing_id = Figaro.env.dev_test_user
         # end
         redirect_to "/unauthorized" and return if computing_id.nil?

         @curr_user = User.find_by(computing_id: computing_id)
         redirect_to "/unauthorized" if @curr_user.nil?
      end
   end
end
