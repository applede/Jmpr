class PlayController < BaseController
  def makeView(frame)
    VideoPlayerView.alloc.initWithFrame(frame)
  end

  def item=(item)
    @item = item
  end

  def activate
    @view.path = @item.videoPath
    super
  end

  def escPressed
    @view.stop
    super
  end

  def enterPressed
    @view.enterPressed
  end
end
