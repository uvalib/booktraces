class ReportsController < ApplicationController
  skip_before_action :authorize

  def set_page
     @page = :reports
  end

  def index
  end
end
