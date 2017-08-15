import Cocoa

import MobileCenter
import MobileCenterAnalytics
import MobileCenterCrashes
import MobileCenterPush

@NSApplicationMain
@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate, MSCrashesDelegate, MSPushDelegate {

  override init(){
    super.init()

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

    // Push Delegate.
    MSPush.setDelegate(self);

    // Start MobileCenter.
    MSMobileCenter.setLogLevel(MSLogLevel.verbose)
    MSMobileCenter.setLogUrl("https://in-integration.dev.avalanch.es")
    MSMobileCenter.start("7ee5f412-02f7-45ea-a49c-b4ebf2911325", withServices : [ MSAnalytics.self, MSCrashes.self, MSPush.self ])

    MobileCenterProvider.shared().mobileCenter = MobileCenterDelegateSwift()
  }

  // Crashes Delegate
  
  func crashes(_ crashes: MSCrashes!, shouldProcessErrorReport errorReport: MSErrorReport!) -> Bool {
    NSLog("Should process error report with: %@", errorReport.exceptionReason);
    return true
  }
  
  func crashes(_ crashes: MSCrashes!, willSend errorReport: MSErrorReport!) {
    NSLog("Will send error report with: %@", errorReport.exceptionReason);
  }
  
  func crashes(_ crashes: MSCrashes!, didSucceedSending errorReport: MSErrorReport!) {
    NSLog("Did succeed error report sending with: %@", errorReport.exceptionReason);
  }
  
  func crashes(_ crashes: MSCrashes!, didFailSending errorReport: MSErrorReport!, withError error: Error!) {
    NSLog("Did fail sending report with: %@, and error: %@", errorReport.exceptionReason, error.localizedDescription);
  }

  // Push Delegate

  func push(_ push: MSPush!, didReceive pushNotification: MSPushNotification!) {
    NSLog("Push received!");
  }
}
