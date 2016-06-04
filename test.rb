class MyAdd
  def add(a,b)
    a + b
  end
end


class MyClass
  def self.newAdd
    MyAdd.new
  end

  def self.delegate(*methods, options)
    return unless options.has_key?(:to)

    methods.each do |method|
      define_method method, ->(*args, &prc) do
        delegated_to = Object.const_get(options[:to]).call()
        delegated_to.send(method, *args, &prc)
      end
    end
  end

  class << self
    delegate :add, to: :newAdd
  end
end
