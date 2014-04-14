class Movie < NSObject
  def initPath(path)
    init
    @path = path
    self
  end

  def fanart
    File.join(@path, 'fanart.jpg')
  end
end
