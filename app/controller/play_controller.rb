#
#  player controller
#
#  Created by Jake Song on 2014-04-18.
#  Copyright (c) 2014 Jake Song. All rights reserved.
#

class PlayController < BaseController
  def makeView(frame)
    VideoPlayerView.alloc.initWithFrame(frame)
  end

  def show(item)
    @item = item
    super
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
