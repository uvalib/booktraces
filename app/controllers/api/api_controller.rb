class Api::ApiController < ApplicationController
   skip_before_action :authorize
end
