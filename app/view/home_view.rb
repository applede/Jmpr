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

  def sections=(sections)
    @current = 0
    @sections = sections
    @layers = @sections.map do |section|
      layer = CATextLayer.layer
      layer.anchorPoint = CGPointMake(0, 0)
      layer.string = section.name
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

  def moveSelection(dir)
    unselect(@current)
    @current = (@current + dir) % @sections.length
    setLayerPositions
    select(@current)
  end

  def select(i)
    layer = @layers[i]
    layer.foregroundColor = NSColor.whiteColor.CGColor
    layer.shadowColor = NSColor.whiteColor.CGColor
    layer.shadowOpacity = 1.0
    layer.shadowOffset = CGSizeMake(0, 0)
  end

  def unselect(i)
    layer = @layers[i]
    layer.foregroundColor = NSColor.blackColor.CGColor
    layer.shadowOpacity = 0.0
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

  def showFanart(path)
    image = NSImage.alloc.initByReferencingFile(path)
    rep = image.representations[0]
    if rep.pixelsWide != rep.size.width
      size = NSMakeSize(rep.pixelsWide, rep.pixelsHigh)
      newImage = NSImage.alloc.initWithSize(size)
      newImage.lockFocus
      image.drawInRect(NSMakeRect(0, 0, size.width, size.height))
      newImage.unlockFocus
      image = newImage
    end
    self.layer.contents = image
    crossfade = CABasicAnimation.animationWithKeyPath('contents')
    crossfade.duration = 0.5
    crossfade.removedOnCompletion = true
    self.layer.addAnimation(crossfade, forKey: nil)
  end

  def didResize
    size = self.bounds.size
    @sectionHeight = size.height * 160 / 1080
    @sectionWidth = size.width * 400 / 1920
    y = @sectionHeight
    @bar.frame = CGRectMake(0, y, size.width, @sectionHeight)
    x = (size.width - @sectionWidth) / 2
    @layers.each do |layer|
      layer.frame = CGRectMake(x, 0, @sectionWidth, @sectionHeight * 76 / 80)
      layer.fontSize = @sectionHeight * 0.7
      x += @sectionWidth
    end
    setLayerPositions
  end
end
