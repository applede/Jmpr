def scanQue
  if $scanQue
    $scanQue
  else
    $scanQue = Dispatch::Queue.new('jmpr.scan')
  end
end

def newTextLayer
  layer = CATextLayer.layer
  layer.anchorPoint = CGPointMake(0, 0)
  layer.foregroundColor = NSColor.blackColor.CGColor
  layer.font = 'HelveticaNeue-Light'
  layer
end

def newLeftTextLayer
  layer = newTextLayer
  layer.alignmentMode = KCAAlignmentLeft
  layer
end

def newCenterTextLayer
  layer = newTextLayer
  layer.alignmentMode = KCAAlignmentCenter
  layer
end

def normalWidth(w)
  w * MasterController.window.contentView.bounds.size.width / 1920
end

def normalHeight(h)
  h * MasterController.window.contentView.bounds.size.height / 1080
end

def centerRect(w, h)
  size = MasterController.window.contentView.bounds.size
  x = (size.width - w) / 2
  y = (size.height - h) / 2
  CGRectMake(x, y, w, h)
end

def highlight(layer)
  layer.foregroundColor = NSColor.whiteColor.CGColor
  layer.shadowColor = NSColor.whiteColor.CGColor
  layer.shadowOpacity = 1.0
  layer.shadowOffset = CGSizeMake(0, 0)
end
