#
#  MyView.m
#  Jap
#
#  Created by Jake Song on 3/23/14.
#  Copyright (c) 2014 Jake Song. All rights reserved.
#

class VideoPlayerView < BaseView
  def initWithFrame(frame)
    super
    self.setWantsBestResolutionOpenGLSurface(true)
    @glLayer = self.layer
    self.setLayerContentsRedrawPolicy(NSViewLayerContentsRedrawDuringViewResize)
    self.makeSublayers
    @controlShown = false
    self
  end

  def makeBackingLayer
    MyOpenGLLayer.layer
  end

  def makeSublayers
    @subtitle = CATextLayer.layer
    @subtitle.alignmentMode = KCAAlignmentCenter
    @subtitle.font = 'HelveticaNeue-Light'
    @subtitle.shadowOpacity = 1.0
    @subtitle.shadowOffset = CGSizeMake(0.0, -1.0)

    @mediaControl = MediaControlLayer.layer
    @mediaControl.view = self
    @mediaControl.anchorPoint = CGPointMake(0, 0)

    self.layer.layoutManager = CAConstraintLayoutManager.layoutManager
    self.layer.addSublayer(@subtitle)
    self.layer.addSublayer(@mediaControl)
  end

  def didResize
    @resizing = false
    if @glLayer.frameChanged
      s = @glLayer.contentsScale
      h = @glLayer.movieRect.size.height / s
      y = @glLayer.movieRect.origin.y / s

      fontSize = h * 0.08
      if @glLayer.decoder.subtitleTrack.encoding == KCFStringEncodingDOSKorean
        @subtitleFont = NSFont.fontWithName('Apple SD Gothic Neo Medium', size:fontSize)
      end
      if !@subtitleFont or @glLayer.decoder.subtitleTrack.encoding != KCFStringEncodingDOSKorean
        @subtitleFont = NSFont.fontWithName('Helvetica Neue Medium', size:fontSize)
      end

      CATransaction.begin
      CATransaction.setDisableActions(true)

      setConstraints(@subtitle, [
        CAConstraint.constraintWithAttribute(KCAConstraintMidX, relativeTo:'superlayer',
          attribute:KCAConstraintMidX),
        CAConstraint.constraintWithAttribute(KCAConstraintMinY, relativeTo:'superlayer',
          attribute:KCAConstraintMinY, offset:y)])
      mh = self.bounds.size.height * 128.0 / 1080.0
      @mediaControl.bounds = [[0, 0], [self.bounds.size.width, mh]]
      if @controlShown
        @mediaControl.position = CGPointMake(0, 0)
      else
        @mediaControl.position = CGPointMake(0, -mh)
      end
      self.layer.setNeedsLayout

      CATransaction.commit
    end
  end

  def path=(path)
    @path = path
  end

  def slideIn
    @glLayer.subtitleDelegate = self
    @glLayer.open(@path)
    self.didResize
  end

  def willResize
    @resizing = true
    @subtitle.string = ''
  end

  def displaySubtitle
    return if @resizing

    newString = @glLayer.decoder.subtitleString
    if newString
      attrs = { NSFontAttributeName => @subtitleFont,
                NSForegroundColorAttributeName => NSColor.whiteColor,
                NSStrokeWidthAttributeName => -1.0,
                NSStrokeColorAttributeName => NSColor.blackColor }
      str = NSAttributedString.alloc.initWithString(newString, attributes:attrs)

      CATransaction.begin
      CATransaction.disableActions = true
      @subtitle.string = str
      CATransaction.commit
    end
  end

  # def keyDown(theEvent)
  #   chars = theEvent.charactersIgnoringModifiers
  #   case chars.characterAtIndex(0)
  #   when 109 # m
  #     @handler.menuPressed
  #   when 13 # \r
  #     @handler.enterPressed
  #   when 32 # space
  #     self.spacePressed
  #   when NSLeftArrowFunctionKey
  #     @handler.leftPressed
  #   when NSRightArrowFunctionKey
  #     @handler.rightPressed
  #   when 27
  #     @handler.escPressed
  #   else
  #   end
  # end

  def menuPressed
    if @controlShown
      @mediaControl.menuPressed
      @controlShown = false
    else
      self.layer.addSublayer(@mediaControl)
      @mediaControl.position = CGPointMake(0, 0)
      @controlShown = true
    end
  end

  # def enterPressed
  #   self.window.toggleFullScreen(self)
  # end

  # def escPressed
  #   self.window.toggleFullScreen(self)
  # end

  def spacePressed
    if @glLayer.decoder.isPlaying
      @glLayer.decoder.pause
    else
      @glLayer.decoder.play
    end
  end

  def leftPressed
    if @controlShown
      @mediaControl.leftPressed
    else
      @glLayer.decoder.seek(-10.0)
    end
  end

  def rightPressed
    if @controlShown
      @mediaControl.rightPressed
    else
      @glLayer.decoder.seek(10.0)
    end
  end

  def pause
    @glLayer.decoder.pause
  end

  def play
    @glLayer.decoder.play
  end

  def slideOutSub
  end
end
