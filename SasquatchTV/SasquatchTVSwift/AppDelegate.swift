// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit;
import AppCenter;
import AppCenterAnalytics;
import AppCenterCrashes;

@UIApplicationMain

class AppDelegate : UIResponder, UIApplicationDelegate, MSCrashesDelegate {

  var window : UIWindow?;

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    // Override point for customization after application launch.
    MSAppCenter.setLogLevel(MSLogLevel.verbose);
    MSAppCenter.start("e57f6975-9167-4b3b-b450-bbb87b717b82", withServices : [MSAnalytics.self, MSCrashes.self]);

    // Crashes Delegate.
    MSCrashes.setDelegate(self)
    MSCrashes.setUserConfirmationHandler({ (errorReports: [MSErrorReport]) in
      let alertController = UIAlertController(title: "Sorry about that!",
              message: "Do you want to send an anonymous crash report so we can fix the issue?",
              preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: "Send", style: .default) { _ in
          MSCrashes.notify(with: .send)
      })
      alertController.addAction(UIAlertAction(title: "Always send", style: .default) { _ in
          MSCrashes.notify(with: .always)
      })
      alertController.addAction(UIAlertAction(title: "Don't send", style: .cancel) { _ in
          MSCrashes.notify(with: .dontSend)
      })
      self.window?.rootViewController?.present(alertController, animated: true)
      return true
    })

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
  func crashes(_ crashes: MSCrashes!, shouldProcessErrorReport errorReport: MSErrorReport!) -> Bool {
    return true
  }

  func crashes(_ crashes: MSCrashes!, willSend errorReport: MSErrorReport!) {
  }

  func crashes(_ crashes: MSCrashes!, didSucceedSending errorReport: MSErrorReport!) {
  }

  func crashes(_ crashes: MSCrashes!, didFailSending errorReport: MSErrorReport!, withError error: Error!) {
  }

  func attachments(with crashes: MSCrashes, for errorReport: MSErrorReport) -> [MSErrorAttachmentLog] {
    let attachment1 = MSErrorAttachmentLog.attachment(withText: "Hello world!", filename: "hello.txt")
    let attachment2 = MSErrorAttachmentLog.attachment(withBinary: "Fake image".data(using: String.Encoding.utf8), filename: nil, contentType: "image/jpeg")
    return [attachment1!, attachment2!]
  }

}
