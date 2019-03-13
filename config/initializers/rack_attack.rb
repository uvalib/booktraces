
# Always allow requests from localhost
# (blocklist & throttles are skipped)
Rack::Attack.safelist('allow ALL from localhost') do |req|
  # Requests are allowed if the return value is truthy
  '127.0.0.1' == req.ip || '::1' == req.ip || 'localhost' == req.host || from_frontend?(req)
end

Rack::Attack.throttle("3 API requests per sec", limit: 3, period: 1) do |req|
   req.path =~ /^\/api/
end


ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, req|
  if req.env["rack.attack.match_type"] == :throttle
    Rails.logger.info "[Rack::Attack][Blocked] remote_ip: \"#{remote_ip(req)}\", path: \"#{req.path}\", headers: #{req.env}"
  end
end

def from_frontend?(request)
   return !request.cookies['bt_api'].nil?
end

def remote_ip(req) 
   ip = req.env['action_dispatch.remote_ip']
   ip = req.ip if ip.nil?
   return ip.to_s
end
