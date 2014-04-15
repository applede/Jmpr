class ListView < BaseView
  def initWithFrame(frame)
    super
    @list = BlurLayer.layer
    @list.anchorPoint = CGPointMake(0, 0)
    @list.cornerRadius = 4
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
      layer = CATextLayer.layer
      layer.anchorPoint = CGPointMake(0, 0)
      layer.string = item.name
      layer.foregroundColor = NSColor.blackColor.CGColor
      layer.font = "HelveticaNeue-Light"
      layer.alignmentMode = KCAAlignmentLeft
      @list.addSublayer(layer)
      layer
    end
    didResize
    select(@current)
  end

  def didResize
    size = self.bounds.size
    @listX = size.width * 20 / 1920
    @listY = size.width * 20 / 1920
    @listWidth = size.width * 1000 / 1920
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
end
