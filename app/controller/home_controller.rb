class HomeController < BaseController
  def initWindow(window)
    super
    @sections = [
      Section.alloc.initName('영화', ['/Users/apple/hobby/test_jamp/movie']),
      Section.alloc.initName('TV', []),
      Section.alloc.initName('음악', []),
      Section.alloc.initName('설정', [])
    ]
    self
  end

  def activate
    unless @view
      @view = HomeView.alloc.initWithFrame(@window.contentView.frame)
      @view.sections = @sections
    end
    @window.delegate = self
    @window.contentView = @view
    @window.makeFirstResponder(@view)
    showRandomFanart
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
end
