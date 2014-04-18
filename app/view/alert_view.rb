#
#  alert view
#
#  Created by Jake Song on 2014-04-18.
#  Copyright (c) 2014 Jake Song. All rights reserved.
#

class AlertView < BaseView
  def initWithFrame(frame)
    super
    @alert = BlurLayer.layer
    @alert.anchorPoint = CGPointMake(0, 0)
    @alert.cornerRadius = 8
    @message = newCenterTextLayer
    @message.wrapped = true
    @ok = newCenterTextLayer
    @layers = [@ok]
    didResize
    self.layer.addSublayer(@alert)
    @alert.addSublayer(@message)
    @alert.addSublayer(@ok)
    self
  end

  def didResize
    alertWidth = normalWidth(500)
    alertHeight = normalHeight(250)
    @alert.frame = centerRect(alertWidth, alertHeight)
    xMargin = normalWidth(20)
    yMargin = normalHeight(10)
    buttonHeight = normalHeight(50)
    x = xMargin
    y = yMargin + buttonHeight + yMargin
    w = alertWidth - xMargin - xMargin
    h = alertHeight - yMargin - y
    @message.frame = CGRectMake(x, y, w, h)
    @message.fontSize = normalHeight(36)
    @ok.frame = CGRectMake(0, yMargin, alertWidth, buttonHeight)
    @ok.fontSize = normalHeight(36)
    @ok.string = 'OK'
  end

  def message=(message)
    @message.string = message
    didResize
    select(0)
  end

  def slideIn
  end

  def slideOutSub
  end
end
