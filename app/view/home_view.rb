class HomeView < BaseView
  def initWithFrame(frame)
    super
    @bar = BlurLayer.layer
    @bar.anchorPoint = CGPointMake(0, 0)
    @layers = []
    @current = 0
    didResize
    self.layer.addSublayer(@bar)
    self
  end

  def items=(items)
    @current = 0
    @items = items
    @bar.sublayers = nil
    @layers = @items.map do |item|
      layer = CATextLayer.layer
      layer.anchorPoint = CGPointMake(0, 0)
      layer.string = item.name
      layer.foregroundColor = NSColor.blackColor.CGColor
      layer.font = "HelveticaNeue-Light"
      layer.alignmentMode = KCAAlignmentCenter
      @bar.addSublayer(layer)
      layer
    end
    didResize
    select(@current)
  end

  def leftPressed
    moveSelection(-1)
  end

  def rightPressed
    moveSelection(1)
  end

  def setLayerPositions
    x = (self.bounds.size.width - @sectionWidth) / 2 - @current * @sectionWidth
    @layers.each do |layer|
      layer.position = CGPointMake(x, 0)
      x += @sectionWidth
    end
  end

  def current
    @current
  end

  def didResize
    size = self.bounds.size
    @sectionHeight = size.height * 160 / 1080
    @sectionWidth = size.width * 400 / 1920
    y = @in ? @sectionHeight : -@sectionHeight
    @bar.frame = CGRectMake(0, y, size.width, @sectionHeight)
    x = (size.width - @sectionWidth) / 2
    @layers.each do |layer|
      layer.frame = CGRectMake(x, 0, @sectionWidth, @sectionHeight * 76 / 80)
      layer.fontSize = @sectionHeight * 0.7
      x += @sectionWidth
    end
    setLayerPositions
  end

  def slideOutSub
    @bar.position = CGPointMake(0, -@sectionHeight)
  end

  def slideIn
    @bar.position = CGPointMake(0, @sectionHeight)
    @in = true
  end
end
