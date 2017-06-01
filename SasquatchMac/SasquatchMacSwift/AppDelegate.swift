import Cocoa

import MobileCenter
import MobileCenterAnalytics
import MobileCenterCrashes

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MSCrashesDelegate {

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    MSMobileCenter.setLogLevel(MSLogLevel.verbose)
    MSMobileCenter.setLogUrl("https://in-integration.dev.avalanch.es")
    MSMobileCenter.start("7ee5f412-02f7-45ea-a49c-b4ebf2911325", withServices : [ MSAnalytics.self, MSCrashes.self ])
    
    // Crashes Delegate.
    MSCrashes.setDelegate(self);
    MSCrashes.setUserConfirmationHandler({ (errorReports: [MSErrorReport]) in
      let alert = MSAlertController.init(title: "Sorry about that!",
                                         message: "Do you want to send an anonymous crash report so we can fix the issue?",
                                         style: .warning)
      alert.addAction(withTitle: "Always Send", handler: {() in
        MSCrashes.notify(with: MSUserConfirmation.always)
      })
      alert.addAction(withTitle: "Send", handler: {() in
        MSCrashes.notify(with: MSUserConfirmation.send)
      })
      alert.addAction(withTitle: "Don't Send", handler: {() in
        MSCrashes.notify(with: MSUserConfirmation.dontSend)
      })
      alert.show()
      return true
    })

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

  // Crashes Delegate
  
  func crashes(_ crashes: MSCrashes!, shouldProcessErrorReport errorReport: MSErrorReport!) -> Bool {
    
    // return true if the crash report should be processed, otherwise false.
    return true
  }
  
  func crashes(_ crashes: MSCrashes!, willSend errorReport: MSErrorReport!) {
    
  }
  
  func crashes(_ crashes: MSCrashes!, didSucceedSending errorReport: MSErrorReport!) {
    
  }
  
  func crashes(_ crashes: MSCrashes!, didFailSending errorReport: MSErrorReport!, withError error: Error!) {
    
  }
}
