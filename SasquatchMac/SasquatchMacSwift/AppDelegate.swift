import Cocoa

import MobileCenterMac
import MobileCenterAnalyticsMac
import MobileCenterCrashesMac

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    MSMobileCenter.setLogLevel(MSLogLevel.verbose)
    MSMobileCenter.setLogUrl("https://in-integration.dev.avalanch.es")
    MSMobileCenter.start("7ee5f412-02f7-45ea-a49c-b4ebf2911325", withServices : [ MSAnalytics.self, MSCrashes.self ])
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
}
