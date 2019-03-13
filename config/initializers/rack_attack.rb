class Request < ::Rack::Request

  # You many need to specify a method to fetch the correct remote IP address
  # if the web server is behind a load balancer.
  def remote_ip
    @remote_ip ||= (env['action_dispatch.remote_ip'] || ip).to_s
  end
end

# Always allow requests from localhost
# (blocklist & throttles are skipped)
Rack::Attack.safelist('allow ALL from localhost') do |req|
  # Requests are allowed if the return value is truthy
  '127.0.0.1' == req.ip || '::1' == req.ip || 'localhost' == req.host || !req.env['HTTP_BOOKTRACES_API_KEY'].nil?
end

Rack::Attack.throttle("3 API requests per sec", limit: 3, period: 1) do |req|
   req.path =~ /^\/api/
end


ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, req|
  if req.env["rack.attack.match_type"] == :throttle
    Rails.logger.info "[Rack::Attack][Blocked] remote_ip: \"#{req.remote_ip}\", path: \"#{req.path}\", headers: #{req.env}"
  end
end
