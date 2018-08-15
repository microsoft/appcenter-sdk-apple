import MobileCoreServices
import Photos
import UIKit

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import AppCenterDistribute
import AppCenterPush

enum startFrom:Int {
  case APP = 0, LIBRARY, BOTH
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MSCrashesDelegate, MSDistributeDelegate, MSPushDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

    // Customize App Center SDK.
    MSCrashes.setDelegate(self)
    MSDistribute.setDelegate(self)
    MSPush.setDelegate(self)
    MSAppCenter.setLogLevel(MSLogLevel.verbose)

    // Start App Center SDK.
    let useOneCollector = UserDefaults.standard.bool(forKey: kMSOneCollectorEnabledKey);
    let startTarget = UserDefaults.standard.integer(forKey: kMSStartTargetKey);
    
    let secretString = useOneCollector
      ? "target=1dd3a9a64e144fcbbd4ce31c5def22e0-e57d4574-c5e7-4f89-a745-b2e850b54185-7090;appsecret=0dbca56b-b9ae-4d53-856a-7c2856137d85"
      : "0dbca56b-b9ae-4d53-856a-7c2856137d85";
    
    switch startTarget {
    case startFrom.LIBRARY.rawValue:
      MSAppCenter.startFromLibrary(withServices: [MSAnalytics.self])
      break;
    case startFrom.APP.rawValue:
      MSAppCenter.start(secretString, withServices: [MSAnalytics.self, MSCrashes.self, MSDistribute.self, MSPush.self])
      break;
    case startFrom.BOTH.rawValue:
      MSAppCenter.startFromLibrary(withServices: [MSAnalytics.self])
      MSAppCenter.start(secretString, withServices: [MSAnalytics.self, MSCrashes.self, MSDistribute.self, MSPush.self])
      break;
    default:
      break;
    }
    
    // Crashes Delegate.
    MSCrashes.setUserConfirmationHandler({ (errorReports: [MSErrorReport]) in

      // Show a dialog to the user where they can choose if they want to update.
      let alertController = UIAlertController(title: "Sorry about that!",
                                              message: "Do you want to send an anonymous crash report so we can fix the issue?",
                                              preferredStyle:.alert)

      // Add a "Don't send"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationDontSend
      alertController.addAction(UIAlertAction(title: "Don't send", style: .cancel) {_ in
        MSCrashes.notify(with: .dontSend)
      })

      // Add a "Send"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationSend
      alertController.addAction(UIAlertAction(title: "Send", style: .default) {_ in
        MSCrashes.notify(with: .send)
      })

      // Add a "Always send"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationAlways
      alertController.addAction(UIAlertAction(title: "Always send", style: .default) {_ in
        MSCrashes.notify(with: .always)
      })

      // Show the alert controller.
      self.window?.rootViewController?.present(alertController, animated: true)

      return true
    })

    setAppCenterDelegate()

    return true
  }

  private func setAppCenterDelegate(){
    let tabBarController = window?.rootViewController as? UITabBarController
    let delegate = AppCenterDelegateSwift()
    for controller in tabBarController!.viewControllers! {
      if controller is AppCenterProtocol {
        (controller as! AppCenterProtocol).appCenter = delegate
      }
    }
  }

  /**
   * (iOS 9+) Asks the delegate to open a resource specified by a URL, and provides a dictionary of launch options.
   *
   * @param app The singleton app object.
   * @param url The URL resource to open. This resource can be a network resource or a file.
   * @param options A dictionary of URL handling options.
   * For information about the possible keys in this dictionary and how to handle them, @see
   * UIApplicationOpenURLOptionsKey. By default, the value of this parameter is an empty dictionary.
   *
   * @return `YES` if the delegate successfully handled the request or `NO` if the attempt to open the URL resource
   * failed.
   */
  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    // Forward the URL.
    return MSDistribute.open(url)
  }

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    MSPush.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
  }

  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    MSPush.didFailToRegisterForRemoteNotificationsWithError(error)
  }

  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    let result: Bool = MSPush.didReceiveRemoteNotification(userInfo)
    if result {
      completionHandler(.newData)
    } else {
      completionHandler(.noData)
    }
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
  
  func attachments(with crashes: MSCrashes, for errorReport: MSErrorReport) -> [MSErrorAttachmentLog] {
    var attachments = [MSErrorAttachmentLog]()
    
    // Text attachment.
    let text = UserDefaults.standard.string(forKey: "textAttachment") ?? ""
    if !text.isEmpty {
      let textAttachment = MSErrorAttachmentLog.attachment(withText: text, filename: "user.log")!
      attachments.append(textAttachment)
    }
    
    // Binary attachment.
    let referenceUrl = UserDefaults.standard.url(forKey: "fileAttachment")
    if referenceUrl != nil {
      let asset = PHAsset.fetchAssets(withALAssetURLs: [referenceUrl!], options: nil).lastObject
      if asset != nil {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        PHImageManager.default().requestImageData(for: asset!, options: options, resultHandler: {(imageData, dataUTI, orientation, info) -> Void in
          let pathExtension = NSURL(fileURLWithPath: dataUTI!).pathExtension
          let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue()
          let mime = UTTypeCopyPreferredTagWithClass(uti!, kUTTagClassMIMEType)?.takeRetainedValue() as NSString?
          let binaryAttachment = MSErrorAttachmentLog.attachment(withBinary: imageData, filename: dataUTI, contentType: mime! as String)!
          attachments.append(binaryAttachment)
          print("Add binary attachment with \(imageData?.count ?? 0) bytes")
        })
      }
    }
    return attachments
  }

  // Distribute Delegate

  func distribute(_ distribute: MSDistribute!, releaseAvailableWith details: MSReleaseDetails!) -> Bool {

    if UserDefaults.standard.bool(forKey: kSASCustomizedUpdateAlertKey) {

      // Show a dialog to the user where they can choose if they want to update.
      let alertController = UIAlertController(title: NSLocalizedString("distribute_alert_title", tableName: "Sasquatch", comment: ""),
                                              message: NSLocalizedString("distribute_alert_message", tableName: "Sasquatch", comment: ""),
                                              preferredStyle:.alert)

      // Add a "Yes"-Button and call the notifyUpdateAction-callback with MSUserAction.update
      alertController.addAction(UIAlertAction(title: NSLocalizedString("distribute_alert_yes", tableName: "Sasquatch", comment: ""), style: .cancel) {_ in
        MSDistribute.notify(.update)
      })

      // Add a "No"-Button and call the notifyUpdateAction-callback with MSUserAction.postpone
      alertController.addAction(UIAlertAction(title: NSLocalizedString("distribute_alert_no", tableName: "Sasquatch", comment: ""), style: .default) {_ in
        MSDistribute.notify(.postpone)
      })

      // Show the alert controller.
      self.window?.rootViewController?.present(alertController, animated: true)
      return true
    }
    return false
  }

  // Push Delegate

  func push(_ push: MSPush!, didReceive pushNotification: MSPushNotification!) {
    let title: String = pushNotification.title ?? ""
    var message: String = pushNotification.message ?? ""
    var customData: String = ""
    for item in pushNotification.customData {
      customData =  ((customData.isEmpty) ? "" : "\(customData), ") + "\(item.key): \(item.value)"
    }
    if (UIApplication.shared.applicationState == .background) {
      NSLog("Notification received in background, title: \"\(title)\", message: \"\(message)\", custom data: \"\(customData)\"");
    } else {
      message =  message + ((customData.isEmpty) ? "" : "\n\(customData)")

      let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: "OK", style: .cancel))

      // Show the alert controller.
      self.window?.rootViewController?.present(alertController, animated: true)
    }
  }
}

