class AlertLayer < BlurLayer
  def init
    super
    self.cornerRadius = 8
    @message = newCenterTextLayer
    @message.wrapped = true
    @ok = newCenterTextLayer
    self.addSublayer(@message)
    self.addSublayer(@ok)
    self
  end

  def setFrame(r)
    super
    xMargin = normalWidth(20)
    yMargin = normalHeight(10)
    buttonHeight = normalHeight(50)
    x = xMargin
    y = yMargin + buttonHeight + yMargin
    w = r.size.width - xMargin - xMargin
    h = r.size.height - yMargin - y
    @message.frame = CGRectMake(x, y, w, h)
    @message.fontSize = normalHeight(36)
    @ok.frame = CGRectMake(0, yMargin, r.size.width, buttonHeight)
    @ok.fontSize = normalHeight(36)
    @ok.string = 'OK'
  end

  def message=(message)
    @message.string = message
    highlight(@ok)
  end

  def setContentsScale(f)
    super
    @message.setContentsScale(f)
    @ok.setContentsScale(f)
  end
end
