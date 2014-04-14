class BaseController < NSObject
  def initWindow(window)
    init
    @window = window
    self
  end

  def windowDidResize(notification)
    @view.didResize
  end
end
