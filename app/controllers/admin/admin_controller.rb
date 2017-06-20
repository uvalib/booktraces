class Admin::AdminController < ApplicationController
   # All admin pages go thru shibboleth and require https
   force_ssl unless Rails.env.development?
end
