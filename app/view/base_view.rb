class BaseView < NSView
  def initWithFrame(frame)
    super
    self.wantsLayer = true
    self.layerUsesCoreImageFilters = true
    self.layer.backgroundColor = NSColor.blackColor.CGColor
    self.layer.contentsGravity = KCAGravityResizeAspect
    self
  end

  def method_missing(name, *args)
  end

  def viewDidChangeBackingProperties
    puts 'viewDidChangeBackingProperties'
    f = self.window.backingScaleFactor
    self.layer.sublayers.each do |layer|
      layer.contentsScale = f
    end
  end

  def keyDown(event)
    chars = event.charactersIgnoringModifiers
    case chars.characterAtIndex(0)
    when 109
      self.menuPressed
    when 13
      self.enterPressed
    when 27
      self.escPressed
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
end