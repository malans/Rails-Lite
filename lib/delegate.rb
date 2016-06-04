module Delegate
  def delegate(*methods, options)
    return unless options.has_key?(:to)

    methods.each do |method|
      define_method method, ->(*args, &prc) do
        delegated_to = self.send(options[:to])
        delegated_to.send(method, *args, &prc)
      end
    end
  end
end
