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
