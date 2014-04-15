class AppDelegate
  def applicationDidFinishLaunching(notification)
    buildMenu
    buildWindow
  end

  def applicationShouldTerminateAfterLastWindowClosed(notification)
    true
  end

  def buildWindow
    @mainWindow = NSWindow.alloc.initWithContentRect([[240, 180], [960, 540]],
      styleMask: NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask,
      backing: NSBackingStoreBuffered,
      defer: false)
    @mainWindow.title = NSBundle.mainBundle.infoDictionary['CFBundleName']
    # @playerView = PlayerView.alloc.initWithFrame([[0, 0], [480, 360]])
    # @mainWindow.contentView = @playerView
    @mainWindow.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary
    # @mainWindow.makeFirstResponder(@playerView)
    @controller = MasterController.alloc.initWindow(@mainWindow)
    @mainWindow.orderFrontRegardless
    # @mainWindow.toggleFullScreen(self)

    # @playerView.open('/Users/apple/hobby/test_jamp/movie/5 Centimeters Per Second (2007)/5 Centimeters Per Second.mkv')
  end
end
