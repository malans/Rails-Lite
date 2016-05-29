module Util
  def blank?(object)
    object.respond_to?(:empty?) ? !!object.empty? : !object
  end
end
