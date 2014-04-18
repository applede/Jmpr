class HomeController < BaseController
  def init
    super
    self
  end

  def activate
    super
    showRandomFanart
  end

  def makeView(frame)
    HomeView.alloc.initWithFrame(frame)
  end

  def showRandomFanart
    fanart = @sections[@view.current].randomFanart
    delay = if fanart
      @view.showFanart(fanart)
      10.0
    else
      0.1
    end
    Dispatch::Queue.main.after(delay) do
      showRandomFanart
    end
  end

  def enterPressed
    @listController = ListController.alloc.init unless @listController
    @listController.show(@sections[@view.current])
  end

  def show(sections)
    @sections = sections
    @view.items = @sections
    super
  end
end
