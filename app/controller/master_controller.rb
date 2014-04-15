class MasterController < NSObject
  def initWindow(aWindow)
    init
    @@instance = self
    @window = aWindow
    @stack = []
    push(HomeController.alloc.init)
    self
  end

  def push(controller)
    if @stack.last
      @stack.last.view.slideOut {
        controller.activate
      }
    else
      controller.activate
    end
    @stack << controller
  end

  def pop
    return if @stack.length <= 1
    current = @stack.pop
    current.view.slideOut {
      @stack.last.activate
    }
  end

  def window
    @window
  end

  def self.window
    @@instance.window
  end

  def self.push(controller)
    @@instance.push(controller)
  end

  def self.pop
    @@instance.pop
  end
end
