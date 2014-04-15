class BaseController < NSObject
  def init
    super
    @view = makeView(MasterController.window.contentView.frame)
    @view.delegate = self
    self
  end

  def view
    @view
  end

  def windowDidResize(notification)
    @view.didResize
  end

  def activate
    window = MasterController.window
    window.delegate = self
    window.contentView = @view
    window.makeFirstResponder(@view)
    Dispatch::Queue.main.async {
      @view.slideIn
    }
  end

  def escPressed
    MasterController.pop
  end
end
