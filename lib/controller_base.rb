require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require_relative './flash'

require 'active_support/inflector'

class ControllerBase
  attr_reader :req, :res, :params

  @@action_queue = []

  # Setup the controller
  def initialize(req, res, route_params = {})
    # req and res are HTTP Request and Response objects
    # route params was obtained from matching the request path with the route path
    @req = req
    @res = res
    @params = route_params.merge(req.params) # req params = query params + body params, packaged by Rack::Request
    @already_built_response = false
  end

  def validate_authenticity_token
    return if req.request_method == "GET"
    return if session["my_form_authenticity_token"] == params["my_authenticity_token"]
    raise "CSRF Attack Detected"
  end

  def my_form_authenticity_token
    session[:my_form_authenticity_token] ||= SecureRandom::urlsafe_base64
  end

  def self.protect_from_forgery(options = {})
    if options[:with] == :exception
      @@action_queue.unshift(:validate_authenticity_token)
    end
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "double render error" if already_built_response?

    @res['Location'] = url
    @res.status = 302

    session.store_session(@res)
    flash.store_flash(@res)

    @already_built_response = true
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise "double render error" if already_built_response?

    @res['Content-Type'] = content_type
    @res.write(content)

    session.store_session(@res)
    flash.store_flash(@res)

    @already_built_response = true
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    # construct path for template_name
    # template naming convention used: "views/#{controller_name}/#{template_name}.html.erb"
    dir_path = File.dirname(__FILE__)
    template_fname = File.join(
      dir_path, "..",
      "views", self.class.name.underscore, "#{template_name}.html.erb"
    )

    layout_template_fname = File.join(
      dir_path, "..",
      "views/layouts/application.html.erb"
    )

    layout_template_code = File.read(layout_template_fname)
    template_code = ERB.new(File.read(template_fname)).result(binding)

    # call render_content to place the template_code in the body of the HTTP response
    # use Kernel#binding to capture the controller's instance variables
    render_content(
      ERB.new(layout_template_code).result(binding),  # evaluate the template_code with packaged environment bindings
      "text/html"
    )
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  def flash
    @flash ||= Flash.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    debugger;
    @@action_queue.push(name)
    @@action_queue.each { |action| self.send(action) }
    render(name) unless @already_built_response
  end
end

class ActionQueue
  def initialize(protect_from_forgery_strategy = nil, action_queue = [])
    @protect_from_forgery_strategy = protect_from_forgery_strategy
    @action_queue = action_queue
  end
end
