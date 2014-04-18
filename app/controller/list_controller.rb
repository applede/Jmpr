#
#  list controller
#
#  Created by Jake Song on 2014-04-18.
#  Copyright (c) 2014 Jake Song. All rights reserved.
#

class ListController < BaseController
  def makeView(frame)
    ListView.alloc.initWithFrame(frame)
  end

  def enterPressed
    @playController = PlayController.alloc.init unless @playController
    @playController.show(@section.items[@view.current])
  end

  def show(section)
    @section = section
    @section.withItems { |items|
      @view.items = items
    }
    super
  end
end
