import UIKit;
import AppCenter;
import AppCenterAnalytics;
import AppCenterCrashes;

@UIApplicationMain

class AppDelegate : UIResponder, UIApplicationDelegate, MSCrashesDelegate {

  var window : UIWindow?;

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

    // Override point for customization after application launch.
    MSAppCenter.setLogLevel(MSLogLevel.verbose);
    MSAppCenter.start("fbdeeff6-a549-4653-9f6d-f97dfe7f07b4", withServices : [MSAnalytics.self, MSCrashes.self]);

    // Crashes Delegate.
    MSCrashes.setDelegate(self)
    MSCrashes.setUserConfirmationHandler({ (errorReports: [MSErrorReport]) in
      let alert = MSAlertController(title: "Sorry about that!",
                                    message: "Do you want to send an anonymous crash report so we can fix the issue?")
      alert?.addDefaultAction(withTitle: "Send", handler: { (alert) in
        MSCrashes.notify(with: MSUserConfirmation.send)
      })
      alert?.addDefaultAction(withTitle: "Always Send", handler: { (alert) in
        MSCrashes.notify(with: MSUserConfirmation.always)
      })
      alert?.addCancelAction(withTitle: "Don't Send", handler: { (alert) in
        MSCrashes.notify(with: MSUserConfirmation.dontSend)
      })
      alert?.show()
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
