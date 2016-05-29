class ActionQueue
  attr_accessor :action_queue

  def initialize(before_action = [], action_queue = [])
    @before_action = before_action
    @action_queue = action_queue
  end

  def clearActionQueue
    @action_queue = []
  end

  def execute(controller, action)
    @before_action.each do |method, options|
      controller.send(method) if options[:only] == :all or options[:only].include?(action)
      if controller.already_built_response?
        clearActionQueue
        return
      end
    end

    until @action_queue.empty?
      controller.send(@action_queue.shift)
    end
  end

  def add_action(action)
    @action_queue.push(action)
  end

  def add_before_action(*methods, **options)
    # options is a hash with a key :only
    # default value is :all which means the methods should be executed before
    # all actions
    defaults = { only: :all }
    options = defaults.merge(options)
    methods.each do |method|
      @before_action.push([method, options])
    end
    # @before_action.concat(actions)
  end
end
