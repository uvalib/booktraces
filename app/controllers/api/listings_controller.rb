class Api::ListingsController < ApplicationController
   # POST query request from datatables
   def query
      draw = params['draw'].to_i
      resp = { draw: draw, recordsTotal: 0, recordsFiltered: 0, data: [] }
      render json: resp
   end
end
