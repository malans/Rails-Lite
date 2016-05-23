require 'json'

class Flash

  def initialize(req)
    cookie = req.cookies["_rails_lite_app_flash"]  #hash
    @flash_now = {}
    @flash = {}

    if cookie
      JSON.parse(cookie).each do |k,v|
        @flash_now[k] = v
      end
    end
  end

  def now
    @flash_now
  end

  def flash
    @flash
  end

  def [](key)
    @flash[key]
  end

  def []=(key, val)
    @flash[key] = val
  end

  def store_flash(res)
    res.set_cookie("_rails_lite_app_flash", {path: "/", value: @flash.to_json})
  end

end
