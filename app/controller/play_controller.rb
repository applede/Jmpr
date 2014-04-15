class PlayController < BaseController
  def makeView(frame)
    VideoPlayerView.alloc.initWithFrame(frame)
  end

  def item=(item)
    @item = item
  end

  def activate
    super
    Dispatch::Queue.main.async {
      @view.open(@item.videoPath)
    }
  end
end
