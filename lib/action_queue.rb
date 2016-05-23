class ActionQueue
  attr_accessor :action_queue

  def initialize(before_action = [], action_queue = [])
    @before_action = before_action
    @action_queue = action_queue
  end

  def execute(object)
    @before_action.each do |action|
      object.send(action)
    end
    # object.send(@protect_from_forgery_strategy) unless @protect_from_forgery_strategy.nil?
    until @action_queue.empty?
      object.send(@action_queue.shift)
    end
  end

  def add_action(action)
    @action_queue.push(action)
  end

  def add_before_action(*actions)
    @before_action.concat(actions)
  end
end
