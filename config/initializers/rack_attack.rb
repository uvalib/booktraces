# Always allow requests from localhost
# (blocklist & throttles are skipped)
Rack::Attack.safelist('allow ALL from localhost') do |req|
  # Requests are allowed if the return value is truthy
  '127.0.0.1' == req.ip || '::1' == req.ip || 'localhost' == req.host
end

Rack::Attack.throttle("3 API requests per sec", limit: 3, period: 1) do |req|
   req.path =~ /^\/api/
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, start, finish, request_id, payload|
  # request object available in payload[:request]
  Rails.logger.warn "Request Throttled: #{name} start: #{start} finish: #{finish} request: #{payload[:request]}"
end
