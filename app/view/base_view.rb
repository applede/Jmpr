class BaseView < NSView
  def initWithFrame(frame)
    super
    # self.layer = CALayer.layer
    self.wantsLayer = true
    self.layerUsesCoreImageFilters = true
    self.layer.backgroundColor = NSColor.blackColor.CGColor
    self.layer.contentsGravity = KCAGravityResizeAspect
    self
  end

  def method_missing(name, *args)
    puts "method_missing #{name}"
  end

  def viewDidChangeBackingProperties
    f = self.window.backingScaleFactor
    setSublayerContentsScale(self.layer, f)
  end

  def setSublayerContentsScale(layer, f)
    if layer.sublayers
      layer.sublayers.each do |sublayer|
        sublayer.contentsScale = f
        setSublayerContentsScale(sublayer, f)
      end
    end
  end

  def delegate=(delegate)
    @delegate = delegate
  end

  def delegate
    @delegate
  end

  def keyDown(event)
    chars = event.charactersIgnoringModifiers
    case chars.characterAtIndex(0)
    when 109
      self.menuPressed
    when 13
      @delegate.enterPressed
    when 27
      @delegate.escPressed
    when NSDownArrowFunctionKey
      self.downPressed
    when NSUpArrowFunctionKey
      self.upPressed
    when NSLeftArrowFunctionKey
      self.leftPressed
    when NSRightArrowFunctionKey
      self.rightPressed
    else
      super
    end
  end

  def moveSelection(dir)
    unselect(@current)
    @current = (@current + dir) % @items.length
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

  def slideOut(&block)
    CATransaction.begin
    CATransaction.completionBlock = block
    slideOutSub
    CATransaction.commit
    @in = false
  end

  def willResize
  end
end
