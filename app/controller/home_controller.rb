class HomeController < BaseController
  def init
    super
    @sections = [
      Section.alloc.initName('영화', ['/Users/apple/hobby/test_jamp/movie']),
      Section.alloc.initName('TV', []),
      Section.alloc.initName('음악', []),
      Section.alloc.initName('설정', [])
    ]
    @view.items = @sections
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
    @listController.section = @sections[@view.current]
    MasterController.push(@listController)
  end
end
