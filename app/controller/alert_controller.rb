#
#  alert controller
#
#  Created by Jake Song on 2014-04-18.
#  Copyright (c) 2014 Jake Song. All rights reserved.
#

class AlertController < BaseController
  def makeView(frame)
    AlertView.alloc.initWithFrame(centerRect(normalWidth(500), normalHeight(250)))
  end

  def show(message)
    @view.message = message
    super
  end

  def escPressed
    enterPressed
  end

  def enterPressed
    # self
    MasterController.pop
    # player view
    # MasterController.pop
  end
end
