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
    MSMobileCenter.start("c62b8db6-191e-496a-b1a1-267b9bf326c4", withServices : [ MSAnalytics.self, MSCrashes.self, MSPush.self ])

    MobileCenterProvider.shared().mobileCenter = MobileCenterDelegateSwift()
  }

  // Crashes Delegate
  
  func crashes(_ crashes: MSCrashes!, shouldProcessErrorReport errorReport: MSErrorReport!) -> Bool {
    if errorReport.exceptionReason != nil {
      NSLog("Should process error report with: %@", errorReport.exceptionReason);
    }
    return true
  }
  
  func crashes(_ crashes: MSCrashes!, willSend errorReport: MSErrorReport!) {
    if errorReport.exceptionReason != nil {
      NSLog("Will send error report with: %@", errorReport.exceptionReason);
    }
  }
  
  func crashes(_ crashes: MSCrashes!, didSucceedSending errorReport: MSErrorReport!) {
    if errorReport.exceptionReason != nil {
      NSLog("Did succeed error report sending with: %@", errorReport.exceptionReason);
    }
  }
  
  func crashes(_ crashes: MSCrashes!, didFailSending errorReport: MSErrorReport!, withError error: Error!) {
    if errorReport.exceptionReason != nil {
      NSLog("Did fail sending report with: %@, and error: %@", errorReport.exceptionReason, error.localizedDescription);
    }
  }

  // Push Delegate

  func push(_ push: MSPush!, didReceive pushNotification: MSPushNotification!) {
    NSLog("Push received!");
  }
}
