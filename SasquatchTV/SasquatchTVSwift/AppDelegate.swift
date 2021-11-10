// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit;
import AppCenter;
import AppCenterAnalytics;
import AppCenterCrashes;

@UIApplicationMain

class AppDelegate : UIResponder, UIApplicationDelegate, CrashesDelegate {

  var window : UIWindow?;

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    // Override point for customization after application launch.
    AppCenter.logLevel = LogLevel.verbose;
    AppCenter.start(withAppSecret: "e57f6975-9167-4b3b-b450-bbb87b717b82", services : [Analytics.self, Crashes.self]);

    // Crashes Delegate.
    Crashes.delegate = self
    Crashes.userConfirmationHandler = ({ (errorReports: [ErrorReport]) in
      let alertController = UIAlertController(title: "Sorry about that!",
              message: "Do you want to send an anonymous crash report so we can fix the issue?",
              preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: "Send", style: .default) { _ in
          Crashes.notify(with: .send)
      })
      alertController.addAction(UIAlertAction(title: "Always send", style: .default) { _ in
          Crashes.notify(with: .always)
      })
      alertController.addAction(UIAlertAction(title: "Don't send", style: .cancel) { _ in
          Crashes.notify(with: .dontSend)
      })
      self.window?.rootViewController?.present(alertController, animated: true)
      return true
    })

      let generatorState = UserDefaults.standard.bool(forKey: kMSAutomaticSessionGenerator)
    if (!generatorState) {
          Analytics.setAutomaticSessionGenerator(generatorState)
      }
    
    setAppCenterDelegate();
    return true;
  }

  func applicationWillResignActive(_ application : UIApplication) {
  }

  func applicationDidEnterBackground(_ application : UIApplication) {
  }

  func applicationWillEnterForeground(_ application : UIApplication) {
  }

  func applicationDidBecomeActive(_ application : UIApplication) {
  }

  func applicationWillTerminate(_ application : UIApplication) {
  }

  private func setAppCenterDelegate() {
    let sasquatchController = self.window?.rootViewController as! AppCenterViewController;
    sasquatchController.appCenter = AppCenterDelegateSwift();
  }

  // Crashes Delegate
  func crashes(_ crashes: Crashes!, shouldProcess errorReport: ErrorReport!) -> Bool {
    if errorReport.exceptionReason != nil {
      NSLog("Should process error report with description: %@", errorReport.description);
    }
    return true
  }

  func crashes(_ crashes: Crashes!, willSend errorReport: ErrorReport!) {
    if errorReport.exceptionReason != nil {
      NSLog("Will send error report: %@", errorReport.description);
    }
  }

  func crashes(_ crashes: Crashes!, didSucceedSending errorReport: ErrorReport!) {
    if errorReport.exceptionReason != nil {
      NSLog("Did succeed sending error report: %@", errorReport.description);
    }
  }

  func crashes(_ crashes: Crashes!, didFailSending errorReport: ErrorReport!, withError error: Error?) {
    if errorReport.exceptionReason != nil {
      NSLog("Did fail sending error report: %@, with error: %@", errorReport.description, error?.localizedDescription ?? "null");
    }
  }

  func attachments(with crashes: Crashes!, for errorReport: ErrorReport!) -> [ErrorAttachmentLog] {
    return PrepareErrorAttachments.prepareAttachments()
  }

}
