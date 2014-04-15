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

  def items
    @items
  end

  def withItems(&block)
    if @items
      block.call(@items)
    else
      scanItems(block)
    end
  end

  def scanItems(&block)
    scanQue.async do
      @items = []
      @folders.each do |folder|
        Dir.foreach(folder) do |fo|
          unless fo[0] == '.'
            @items << Movie.alloc.initPath(File.join(folder, fo))
          end
        end
      end
      Dispatch::Queue.main.async {
        block.call(@items)
      }
    end
  end

  def randomFanart
    if @items
      if @items.length > 0
        @items[Random.rand(@items.length)].fanart
      else
        nil
      end
    else
      scanItems {}
      nil
    end
  end
end
