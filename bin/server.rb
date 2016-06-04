require 'rack'
require_relative '../lib/controller_base'
require_relative '../lib/router'
Dir['./models/*.rb'].each {|file| require file }
require 'byebug'

MIME_TYPES = {
  "js" => "application/javascript",
  "jpg" => "image/jpeg",
  "jpeg" => "image/jpeg",
  "png" => "image/png",
  "css" => "text/css"
}

# global to be accessible in config.routes
# there is likely a better way to do this
$router = Router.new

require_relative './../config/routes'

class StaticAssets
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    if req.path.match(/^\/public/)
      extension = req.path.match(/\.(\w+)/)[1]
      file = File.read("." + req.path)
      res = Rack::Response.new
      res['Content-Type'] = MIME_TYPES[extension]
      res.write(file)
      res.finish
    else
      app.call(env)
    end
  end
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  $router.run(req, res)
  res.finish
end

app_middleware_stack = Rack::Builder.new do
  use StaticAssets
  run app
end.to_app

Rack::Server.start(
 app: app_middleware_stack,
 Port: 3000
)
