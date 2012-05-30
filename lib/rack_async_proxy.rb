require "net/http"
require "net/https"
require 'timeout'

# Example Usage:
#
# use RackAsyncProxy do |req|
#   if req.path =~ %r{^/remote/service.php$}
#     URI.parse("http://remote-service-provider.com/service-end-point?#{req.query}")
#   end
# end
#
# run proc{|env| [200, {"Content-Type" => "text/plain"}, ["Ha ha ha"]] }
#
# Warning doesn't handle https end points
class RackAsyncProxy

  VERSION = "0.0.1"

  def initialize(app, &block)
    self.class.send(:define_method, :uri_for, &block)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    method = req.request_method.downcase
    method[0..0] = method[0..0].upcase

    uri = uri_for(req)
    return @app.call(env) unless uri
    puts "[RackAsyncProxy] got uri: #{uri.inspect}"

    sub_request = Net::HTTP.const_get(method).new("#{uri.path}#{"?" if uri.query}#{uri.query}")

    if sub_request.request_body_permitted? and req.body
      sub_request.body_stream = req.body
      sub_request.content_length = req.content_length
      sub_request.content_type = req.content_type
    end

    sub_request["X-Forwarded-For"] = (req.env["X-Forwarded-For"].to_s.split(/, +/) + [req.env['REMOTE_ADDR']]).join(", ")
    sub_request["X-Requested-With"] = req.env['HTTP_X_REQUESTED_WITH'] if req.env['HTTP_X_REQUESTED_WITH']
    sub_request["Accept-Encoding"] = req.accept_encoding
    sub_request["Referer"] = req.referer
    sub_request.basic_auth *uri.userinfo.split(':') if (uri.userinfo && uri.userinfo.index(':'))

    # We blindly kick off a request in a thread. We don't care if it finishes since this is just for testing
    Thread.new(uri) do |_uri|
      begin 
        Timeout.timeout(30) do
          sub_response = Net::HTTP.start(_uri.host, _uri.port) do |http|
            puts "[RackAsyncProxy] requesting uri: #{uri.inspect}"
            http.read_timeout = 30 # set read timeout to 30 seconds
            http.use_ssl = false   #staging does not use https
            response = http.request(sub_request)
            puts "[RackAsyncProxy] got from uri: #{response.code} #{response.body}"
          end
        end
      rescue Timeout::Error => timeout_error
        $stderr.puts "[Rack::AsyncProxy] Timeout::Error proxying subrequest: #{uri}"

      rescue Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse,
             Net::HTTPHeaderSyntaxError, Net::ProtocolError, Errno::ETIMEDOUT => nethttp_error
        $stderr.puts "[Rack::AsyncProxy] #{nethttp_error.class.name} proxying subrequest: #{uri}"
      rescue Exception => err
        #We don't want any exceptions in the subrequest molesting the main request
        #But we want to know what they are
        $stderr.puts "[Rack::AsyncProxy] #{err.class.name} proxying subrequest: #{uri}: Message: #{err.message}"
        $stderr.puts err.backtrace.join("\n")
      end
    end

    #Just let current request continue up the chain....
    return @app.call(env)
  end
end
