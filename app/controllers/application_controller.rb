class ApplicationController < ActionController::Base
   protect_from_forgery with: :exception
   helper_method :current_user, :logged_in?, :clear_session

   before_action :authorize

   # Shibboleth auth requires all to be https
   force_ssl unless Rails.env.development?

   def current_user
      return @curr_user
   end

   def logged_in?
      return !current_user.nil?
   end

   def clear_session
      session[:user] = nil
      session[:user_type] = nil
      session[:search_state] = nil
   end

   def authorize
      if session[:user_type] == "staff"
         # Shibboleth will stuff the computing ID in REMOTE_USER header. If it
         # is not present or does not match up with a registered book traces
         # staff member, redirect to unauthorized. Exception; dev has a configured
         # fake user to work arond shibboleth auth
         computing_id = request.env['REMOTE_USER'].to_s
         if computing_id.blank? && Rails.env != "production"
            computing_id = Figaro.env.dev_test_user
         end
         redirect_to "/unauthorized" and return if computing_id.nil?

         @curr_user = User.find_by(computing_id: computing_id)
         redirect_to "/unauthorized" if @curr_user.nil?
      else
         redirect_to "/unauthorized"
      end
   end
end
