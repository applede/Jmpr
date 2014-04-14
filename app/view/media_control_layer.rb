#
#  MediaControlLayer.m
#  Jap
#
#  Created by Jake Song on 4/4/14.
#  Copyright (c) 2014 Jake Song. All rights reserved.
#

BUTTON_COUNT = 6
OFF = 0
ON = 1
PAUSE = 2
PLAY = 6

class MediaControlLayer < BlurLayer
  attr_accessor :view

  def init
    super
    imageNames = [
      ['skip-to-start-128-black.png', 'skip-to-start-128-white.png'],
      ['rewind-128-black.png', 'rewind-128-white.png'],
      ['pause-128-black.png', 'pause-128-white.png'],
      ['stop-128-black.png', 'stop-128-white.png'],
      ['fast-forward-128-black.png', 'fast-forward-128-white.png'],
      ['end-128-black.png', 'end-128-white.png'],
      ['play-128-black.png', 'play-128-white.png'],
    ]
    @images = imageNames.map { |names|
      [NSImage.imageNamed(names[OFF]), NSImage.imageNamed(names[ON])]
    }
    @buttons = @images[0..-2].map { |images|
      button = CALayer.layer
      button.contents = images[OFF]
      button.anchorPoint = [0, 0]
      self.addSublayer(button)
      button
    }
    @current = PAUSE
    self.select(@current)
    @playing = true
    self
  end

  def setBounds(bounds)
    super
    h = self.bounds.size.height
    x = (self.bounds.size.width - h * BUTTON_COUNT) / 2;
    @buttons.each do |button|
      button.bounds = [[0, 0], [h, h]]
      button.position = [x, 0]
      x += h
    end
  end

  def setContentsScale(f)
    super
    @buttons.each do |button|
      button.contentsScale = f
    end
  end

  def menuPressed
    NSAnimationContext.runAnimationGroup(->(ctx) {
      self.position = [0, -self.bounds.size.height]
      }, completionHandler:->{
        self.removeFromSuperlayer
        })
    @view.takeFocus
  end

  def enterPressed
    if @current == PAUSE
      @playing = !@playing
      if @playing
        @view.play
        @buttons[PAUSE].contents = @images[PAUSE][ON]
      else
        @view.pause
        @buttons[PAUSE].contents = @images[PLAY][ON]
      end
    end
  end

  def escPressed
    self.menuPressed
  end

  def spacePressed
  end

  def leftPressed
    self.moveCurrent(-1)
  end

  def rightPressed
    self.moveCurrent(1)
  end

  def moveCurrent(dir)
    self.unselect(@current)
    @current = (@current + BUTTON_COUNT + dir) % BUTTON_COUNT
    self.select(@current)
  end

  def select(i)
    @buttons[i].contents = @images[i][ON]
    @buttons[i].shadowColor = NSColor.whiteColor.CGColor
    @buttons[i].shadowOpacity = 1.0
    @buttons[i].shadowOffset = [0, 0]
  end

  def unselect(i)
    @buttons[i].contents = @images[i][OFF]
    @buttons[i].shadowOpacity = 0.0
  end
end