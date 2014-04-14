class Section < NSObject
  def initName(name, folders)
    init
    @name = name
    @folders = folders
    self
  end

  def name
    @name
  end

  def randomFanart
    if @items
      if @items.length > 0
        @items[Random.rand(@items.length)].fanart
      else
        nil
      end
    else
      Dispatch::Queue.new('jmpr.scan').async do
        @items = []
        @folders.each do |folder|
          Dir.foreach(folder) do |fo|
            unless fo[0] == '.'
              @items << Movie.alloc.initPath(File.join(folder, fo))
            end
          end
        end
      end
      nil
    end
  end
end
