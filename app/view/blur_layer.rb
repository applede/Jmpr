#
#  BlurLayer.m
#  Jap
#
#  Created by Jake Song on 4/5/14.
#  Copyright (c) 2014 Jake Song. All rights reserved.
#

class BlurLayer < CALayer
  def init
    super
    self.anchorPoint = CGPointMake(0, 0)
    self.masksToBounds = true
    self.backgroundColor = NSColor.colorWithCalibratedWhite(0.6, alpha:0.7).CGColor
    self.needsDisplayOnBoundsChange = true
    saturationFilter = CIFilter.filterWithName('CIColorControls')
    saturationFilter.setDefaults
    saturationFilter.setValue(2.0, forKey:'inputSaturation')
    clampFilter = CIFilter.filterWithName('CIAffineClamp')
    clampFilter.setDefaults
    clampFilter.setValue(CGAffineTransformMakeScale(1, 1), forKey:'inputTransform')
    blurFilter = CIFilter.filterWithName('CIGaussianBlur')
    blurFilter.setDefaults
    blurFilter.setValue(20.0, forKey:'inputRadius')
    self.backgroundFilters = [saturationFilter, clampFilter, blurFilter]
    self.setNeedsDisplay
    self
  end
end
