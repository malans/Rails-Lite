require 'rack'
require_relative '../lib/controller_base'
require_relative '../lib/router'
Dir['./models/*.rb'].each {|file| require file }
require 'byebug'

# global to be accessible in config.routes
# there is likely a better way to do this
$router = Router.new

require_relative './../config/routes'


app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  $router.run(req, res)
  res.finish
end

Rack::Server.start(
 app: app,
 Port: 3000
)
