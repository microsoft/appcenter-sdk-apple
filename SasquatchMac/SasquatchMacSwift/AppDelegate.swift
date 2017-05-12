import Cocoa

import MobileCenterMac
import MobileCenterAnalyticsMac
import MobileCenterCrashesMac

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    MSAnalytics.setEnabled(ServiceStateStore.AnalyticsState)
    MSCrashes.setEnabled(ServiceStateStore.CrashesState)
    MSMobileCenter.setLogLevel(MSLogLevel.verbose)
    MSMobileCenter.setLogUrl("https://in-integration.dev.avalanch.es")
    MSMobileCenter.start("7ee5f412-02f7-45ea-a49c-b4ebf2911325", withServices : [ MSAnalytics.self, MSCrashes.self ])
    self.setMobileCenterDelegate()
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  func setMobileCenterDelegate() {
    if let sasquatchMacView = NSApplication.shared().mainWindow?.contentViewController as? SasquatchMacViewController {
      sasquatchMacView.mobileCenter = MobileCenterDelegateSwift()
    }
  }
}
