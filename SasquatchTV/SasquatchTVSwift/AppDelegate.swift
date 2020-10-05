// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit;
import AppCenter;
import AppCenterAnalytics;
import AppCenterCrashes;

@UIApplicationMain

class AppDelegate : UIResponder, UIApplicationDelegate, MSACCrashesDelegate {

  var window : UIWindow?;

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    // Override point for customization after application launch.
    MSACAppCenter.setLogLevel(MSACLogLevel.verbose);
    MSACAppCenter.start("e57f6975-9167-4b3b-b450-bbb87b717b82", withServices : [MSACAnalytics.self, MSACCrashes.self]);

    // Crashes Delegate.
    MSACCrashes.setDelegate(self)
    MSACCrashes.setUserConfirmationHandler({ (errorReports: [MSACErrorReport]) in
      let alertController = UIAlertController(title: "Sorry about that!",
              message: "Do you want to send an anonymous crash report so we can fix the issue?",
              preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: "Send", style: .default) { _ in
          MSACCrashes.notify(with: .send)
      })
      alertController.addAction(UIAlertAction(title: "Always send", style: .default) { _ in
          MSACCrashes.notify(with: .always)
      })
      alertController.addAction(UIAlertAction(title: "Don't send", style: .cancel) { _ in
          MSACCrashes.notify(with: .dontSend)
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
  func crashes(_ crashes: MSACCrashes!, shouldProcessErrorReport errorReport: MSACErrorReport!) -> Bool {
    return true
  }

  func crashes(_ crashes: MSACCrashes!, willSend errorReport: MSACErrorReport!) {
  }

  func crashes(_ crashes: MSACCrashes!, didSucceedSending errorReport: MSACErrorReport!) {
  }

  func crashes(_ crashes: MSACCrashes!, didFailSending errorReport: MSACErrorReport!, withError error: Error!) {
  }

  func attachments(with crashes: MSACCrashes, for errorReport: MSACErrorReport) -> [MSACErrorAttachmentLog] {
    let attachment1 = MSACErrorAttachmentLog.attachment(withText: "Hello world!", filename: "hello.txt")
    let attachment2 = MSACErrorAttachmentLog.attachment(withBinary: "Fake image".data(using: String.Encoding.utf8), filename: nil, contentType: "image/jpeg")
    return [attachment1!, attachment2!]
  }

}
