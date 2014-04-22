#
#  list view
#
#  Created by Jake Song on 2014-04-18.
#  Copyright (c) 2014 Jake Song. All rights reserved.
#

class ListView < BaseView
  def initWithFrame(frame)
    super
    @list = BlurLayer.layer
    @list.cornerRadius = 4
    @alert = AlertLayer.layer
    @layers = []
    didResize
    self.layer.addSublayer(@list)
    self
  end

  def items=(items)
    @current = 0
    @items = items
    @list.sublayers = nil
    @layers = @items.map do |item|
      layer = newLeftTextLayer
      layer.string = item.name
      @list.addSublayer(layer)
      layer
    end
    didResize
    select(@current)
  end

  def didResize
    size = self.bounds.size
    @listX = normalWidth(20)
    @listY = normalHeight(20)
    @listWidth = normalWidth(1000)
    h = size.height - @listY - @listY
    x = @in ? @listX : -@listWidth
    @list.frame = CGRectMake(x, @listY, @listWidth, h)
    @itemWidth = @listWidth - @listX - @listX
    @itemHeight = h / 15
    x = @listX
    y = h - @itemHeight
    @layers.each do |layer|
      layer.frame = CGRectMake(x, y, @itemWidth, @itemHeight)
      layer.fontSize = @itemHeight * 0.7
      y -= @itemHeight
    end

    alertWidth = normalWidth(500)
    alertHeight = normalHeight(250)
    @alert.frame = centerRect(alertWidth, alertHeight)
  end

  def select(i)
    super
    showFanart(@items[i].fanart)
  end

  def upPressed
    moveSelection(-1)
  end

  def downPressed
    moveSelection(1)
  end

  def setLayerPositions
  end

  def slideIn
    @list.position = CGPointMake(@listX, @listY)
    @in = true
  end

  def slideOutSub
    @list.position = CGPointMake(-@listWidth, @listY)
  end

  def current
    @current
  end

  def showAlert(message)
    @alert.message = message
    self.layer.addSublayer(@alert)
    f = self.window.backingScaleFactor
    @alert.contentsScale = f
  end
end
