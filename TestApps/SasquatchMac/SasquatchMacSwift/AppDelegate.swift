import Cocoa

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import AppCenterPush

@NSApplicationMain
@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate, MSCrashesDelegate, MSPushDelegate {

  var rootController: NSWindowController!

  func applicationDidFinishLaunching(_ notification: Notification) {
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

    // Start AppCenter.
    MSAppCenter.setLogLevel(MSLogLevel.verbose)
    MSAppCenter.start("7e873482-108f-4609-8ef2-c4cebd7418c0", withServices : [ MSAnalytics.self, MSCrashes.self, MSPush.self ])

    AppCenterProvider.shared().appCenter = AppCenterDelegateSwift()
    
    initUI()
  }

  func initUI() {
    let mainStoryboard = NSStoryboard.init(name: "SasquatchMac", bundle: nil)
    rootController = mainStoryboard.instantiateController(withIdentifier: "rootController") as! NSWindowController
    rootController.showWindow(self)
    rootController.window?.makeKeyAndOrderFront(self)
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
