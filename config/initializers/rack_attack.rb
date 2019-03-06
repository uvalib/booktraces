Rack::Attack.throttle("3 API requests per sec", limit: 3, period: 1) do |req|
   req.path =~ /^\/api/
end
