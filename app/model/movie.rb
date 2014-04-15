class Movie < NSObject
  def initPath(path)
    init
    @path = path
    self
  end

  def name
    File.basename(@path)
  end

  def fanart
    File.join(@path, 'fanart.jpg')
  end

  def videoPath
    return @videoPath if @videoPath
    Dir.foreach(@path) { |file|
      if file.end_with?('mp4', 'mkv')
        @videoPath = File.join(@path, file)
        break
      end
    }
    @videoPath
  end
end
