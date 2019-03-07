class ApiAccessController  < ApplicationController
   skip_before_action :authorize

   def set_page
      @page = :api_request
   end

   def index
   end

   def create
      email = params[:email]
      ak = ApiKey.find_by(email: email)
      if !ak.nil?
         ak.regenerate_key
      else
         ak = ApiKey.new
         ak.email = email
         ak.first_name = params[:first_name]
         ak.last_name = params[:last_name]
         ak.institution = params[:institution]
         if !ak.save
            flash[:error] = ak.errors.full_messages.to_sentence
            render :index
            return
         end
      end
      KeyMailer.with(key: ak).key_email.deliver_later
      render :confirm
   end
end
