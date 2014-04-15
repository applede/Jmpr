class ListController < BaseController
  def makeView(frame)
    ListView.alloc.initWithFrame(frame)
  end

  def section=(section)
    @section = section
    @section.withItems { |items|
      @view.items = items
    }
  end

  def enterPressed
    @playController = PlayController.alloc.init unless @playController
    @playController.item = @section.items[@view.current]
    MasterController.push(@playController)
  end
end
