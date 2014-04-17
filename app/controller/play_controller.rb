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
    @view.pause
    super
  end
end
