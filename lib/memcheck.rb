# Memcheck

module Memcheck
  def self.included(base)
    base.around_filter do |controller, action|
      pre_memory = self.get_memory
      action.call
      self.free_memory
      self.log_memory pre_memory, controller
    end
  end
  
  def self.get_memory
    memory = nil
    IO.popen("ps -o vsz -p #{Process.pid}") do |f|
      f.readline
      memory = f.readline.strip
    end
    memory
  end

  def self.log_memory(pre_memory, controller)
    post_memory = self.get_memory
    change = pre_memory.to_i - post_memory.to_i
    RAILS_DEFAULT_LOGGER.error "MemCheck: #{'+' if change > 0}#{change} [#{pre_memory}-#{post_memory}]: #{controller.controller_name.camelize}##{controller.action_name} (pid=#{Process.pid})"
  end

  def self.free_memory
    disabled = GC.enable
    GC.start
    GC.disable if disabled
  end
end
