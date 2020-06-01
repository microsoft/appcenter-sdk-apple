// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import CoreLocation
import MobileCoreServices
import Photos
import UIKit

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
#if canImport(AppCenterDistribute)
import AppCenterDistribute
#endif
#if canImport(AppCenterPush)
import AppCenterPush
#endif
import UserNotifications

enum StartupMode: Int {
  case APPCENTER
  case ONECOLLECTOR
  case BOTH
  case NONE
  case SKIP
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MSCrashesDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate {

  private var notificationPresentationCompletionHandler: Any?
  private var notificationResponseCompletionHandler: Any?
  private var locationManager : CLLocationManager = CLLocationManager()

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    MSCrashes.setDelegate(self)
#if canImport(AppCenterDistribute)
    MSDistribute.setDelegate(self)
#endif
#if canImport(AppCenterPush)
    MSPush.setDelegate(self)
#endif
    MSAppCenter.setLogLevel(MSLogLevel.verbose)

    // Set max storage size.
    let storageMaxSize = UserDefaults.standard.object(forKey: kMSStorageMaxSizeKey) as? Int
    if storageMaxSize != nil {
      MSAppCenter.setMaxStorageSize(storageMaxSize!, completionHandler: { success in
        DispatchQueue.main.async {
          if success {
            let realSize = Int64(ceil(Double(storageMaxSize!) / Double(kMSStoragePageSize))) * Int64(kMSStoragePageSize)
            UserDefaults.standard.set(realSize, forKey: kMSStorageMaxSizeKey)
          } else {

            // Remove invalid value.
            UserDefaults.standard.removeObject(forKey: kMSStorageMaxSizeKey)

            // Show alert.
            let alertController = UIAlertController(title: "Warning!",
                                                    message: "The maximum size of the internal storage could not be set.",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            self.window?.rootViewController?.present(alertController, animated: true)
          }
        }
      })
    }

    let logUrl = UserDefaults.standard.string(forKey: kMSLogUrl)
    if logUrl != nil {
      MSAppCenter.setLogUrl(logUrl)
    }
#if canImport(AppCenterDistribute)
    if let updateTrackValue = UserDefaults.standard.value(forKey: kMSUpdateTrackKey) as? Int,
       let updateTrack = MSUpdateTrack(rawValue: updateTrackValue) {
        MSDistribute.updateTrack = updateTrack
    }
    if UserDefaults.standard.bool(forKey: kSASAutomaticCheckForUpdateDisabledKey) {
        MSDistribute.disableAutomaticCheckForUpdate()
    }
#endif

    // Start App Center SDK.
    var services = [MSAnalytics.self, MSCrashes.self]
#if canImport(AppCenterDistribute)
    services.append(MSDistribute.self)
#endif
#if canImport(AppCenterPush)
    services.append(MSPush.self)
#endif
    let appSecret = UserDefaults.standard.string(forKey: kMSAppSecret) ?? kMSSwiftCombinedAppSecret
    let startTarget = StartupMode(rawValue: UserDefaults.standard.integer(forKey: kMSStartTargetKey))!
    let latencyTimeValue = UserDefaults.standard.integer(forKey: kMSTransmissionIterval);
    MSAnalytics.setTransmissionInterval(UInt(latencyTimeValue));
    switch startTarget {
    case .APPCENTER:
      MSAppCenter.start(appSecret, withServices: services)
      break
    case .ONECOLLECTOR:
      MSAppCenter.start("target=\(kMSSwiftTargetToken)", withServices: services)
      break
    case .BOTH:
      MSAppCenter.start("appsecret=\(appSecret);target=\(kMSSwiftTargetToken)", withServices: services)
      break
    case .NONE:
      MSAppCenter.start(withServices: services)
      break
    case .SKIP:
      break
    }
    
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    locationManager.requestWhenInUseAuthorization()

    // Set user id.
    let userId = UserDefaults.standard.string(forKey: kMSUserIdKey)
    if userId != nil {
      MSAppCenter.setUserId(userId);
    }

    // Crashes Delegate.
    MSCrashes.setUserConfirmationHandler({ (errorReports: [MSErrorReport]) in

      // Show a dialog to the user where they can choose if they want to update.
      let alertController = UIAlertController(title: "Sorry about that!",
              message: "Do you want to send an anonymous crash report so we can fix the issue?",
              preferredStyle: .alert)

      // Add a "Don't send"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationDontSend
      alertController.addAction(UIAlertAction(title: "Don't send", style: .cancel) { _ in
        MSCrashes.notify(with: .dontSend)
      })

      // Add a "Send"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationSend
      alertController.addAction(UIAlertAction(title: "Send", style: .default) { _ in
        MSCrashes.notify(with: .send)
      })

      // Add a "Always send"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationAlways
      alertController.addAction(UIAlertAction(title: "Always send", style: .default) { _ in
        MSCrashes.notify(with: .always)
      })

      // Show the alert controller.
      self.window?.rootViewController?.present(alertController, animated: true)

      return true
    })

    setAppCenterDelegate()
    return true
  }

  private func setAppCenterDelegate() {
    let tabBarController = window?.rootViewController as? UITabBarController
    let delegate = AppCenterDelegateSwift()
    for controller in tabBarController!.viewControllers! {
      if controller is AppCenterProtocol {
        (controller as! AppCenterProtocol).appCenter = delegate
      } else {
        controller.removeFromParent()
      }
    }
  }

#if canImport(AppCenterDistribute)

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
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    // Forward the URL.
    return MSDistribute.open(url);
  }

#endif
#if canImport(AppCenterPush)

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    MSPush.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
  }

  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    MSPush.didFailToRegisterForRemoteNotificationsWithError(error)
  }

  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    let result: Bool = MSPush.didReceiveRemoteNotification(userInfo)
    if result {
      completionHandler(.newData)
    } else {
      completionHandler(.noData)
    }
  }

#endif

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
#if !targetEnvironment(macCatalyst)
      let asset = PHAsset.fetchAssets(withALAssetURLs: [referenceUrl!], options: nil).lastObject
      if asset != nil {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        PHImageManager.default().requestImageData(for: asset!, options: options, resultHandler: { (imageData, dataUTI, orientation, info) -> Void in
          let pathExtension = NSURL(fileURLWithPath: dataUTI!).pathExtension
          let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue()
          let mime = UTTypeCopyPreferredTagWithClass(uti!, kUTTagClassMIMEType)?.takeRetainedValue() as NSString?
          let binaryAttachment = MSErrorAttachmentLog.attachment(withBinary: imageData, filename: dataUTI, contentType: mime! as String)!
          attachments.append(binaryAttachment)
          print("Add binary attachment with \(imageData?.count ?? 0) bytes")
        })
      }
#else
      do {
        let data = try Data(contentsOf: referenceUrl!)
        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, referenceUrl!.pathExtension as NSString, nil)?.takeRetainedValue()
        let mime = UTTypeCopyPreferredTagWithClass(uti!, kUTTagClassMIMEType)?.takeRetainedValue() as NSString?
        let binaryAttachment = MSErrorAttachmentLog.attachment(withBinary: data, filename: referenceUrl?.lastPathComponent, contentType: mime! as String)!
        attachments.append(binaryAttachment)
        print("Add binary attachment with \(data.count) bytes")
      } catch {
        print(error)
      }
#endif
    }
    return attachments
  }

  func requestLocation() {
    if CLLocationManager.locationServicesEnabled() {
      self.locationManager.requestLocation()
    }
  }

  // CLLocationManager Delegate
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    if status == CLAuthorizationStatus.authorizedWhenInUse {
      manager.requestLocation()
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let userLocation:CLLocation = locations[0] as CLLocation
    CLGeocoder().reverseGeocodeLocation(userLocation) { (placemarks, error) in
      if error == nil {
        MSAppCenter.setCountryCode(placemarks?.first?.isoCountryCode)
      }
    }
  }

  func locationManager(_ Manager: CLLocationManager, didFailWithError error: Error) {
    print("Failed to find user's location: \(error.localizedDescription)")
  }

}

#if canImport(AppCenterDistribute)

extension AppDelegate: MSDistributeDelegate {
  func distribute(_ distribute: MSDistribute!, releaseAvailableWith details: MSReleaseDetails!) -> Bool {
    if UserDefaults.standard.bool(forKey: kSASCustomizedUpdateAlertKey) {

      // Show a dialog to the user where they can choose if they want to update.
      let alertController = UIAlertController(title: NSLocalizedString("distribute_alert_title", tableName: "Sasquatch", comment: ""),
              message: NSLocalizedString("distribute_alert_message", tableName: "Sasquatch", comment: ""),
              preferredStyle: .alert)

      // Add a "Yes"-Button and call the notifyUpdateAction-callback with MSUserAction.update
      alertController.addAction(UIAlertAction(title: NSLocalizedString("distribute_alert_yes", tableName: "Sasquatch", comment: ""), style: .cancel) { _ in
        MSDistribute.notify(.update)
      })

      // Add a "No"-Button and call the notifyUpdateAction-callback with MSUserAction.postpone
      alertController.addAction(UIAlertAction(title: NSLocalizedString("distribute_alert_no", tableName: "Sasquatch", comment: ""), style: .default) { _ in
        MSDistribute.notify(.postpone)
      })

      // Show the alert controller.
      self.window?.rootViewController?.present(alertController, animated: true)
      return true
    }
    return false
  }
}

#endif
#if canImport(AppCenterPush)

extension AppDelegate: MSPushDelegate {
  func push(_ push: MSPush!, didReceive pushNotification: MSPushNotification!) {

    // Alert in foreground if requested from custom data.
    if #available(iOS 10.0, *), notificationPresentationCompletionHandler != nil && pushNotification.customData["presentation"] == "alert" {
      (notificationPresentationCompletionHandler as! (UNNotificationPresentationOptions) -> Void)(.alert)
      notificationPresentationCompletionHandler = nil
      return;
    }

    // Create and show a popup from the notification payload.
    let title: String = pushNotification.title ?? ""
    var message: String = pushNotification.message ?? ""
    var customData: String = ""
    for item in pushNotification.customData {
      customData = ((customData.isEmpty) ? "" : "\(customData), ") + "\(item.key): \(item.value)"
    }
    if (UIApplication.shared.applicationState == .background) {
      NSLog("Notification received in background (silent push), title: \"\(title)\", message: \"\(message)\", custom data: \"\(customData)\"");
    } else {
      if #available(iOS 10.0, *) {
        if (!message.isEmpty) {
          message += "\n"
        }
        if notificationResponseCompletionHandler != nil {
          message += "Tapped notification"
        } else {
          message += "Received in foreground"
        }
      }
      message += (customData.isEmpty ? "" : "\n\(customData)")

      let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: "OK", style: .cancel))

      // Show the alert controller.
      self.window?.rootViewController?.present(alertController, animated: true)
    }

    // Call notification completion handlers.
    if #available(iOS 10.0, *) {
      if (notificationResponseCompletionHandler != nil){
        (notificationResponseCompletionHandler as! () -> Void)()
        notificationResponseCompletionHandler = nil
      }
      if (notificationPresentationCompletionHandler != nil){
        (notificationPresentationCompletionHandler as! (UNNotificationPresentationOptions) -> Void)([])
        notificationPresentationCompletionHandler = nil
      }
    }
  }

  // Native push delegates
  @available(iOS 10.0, *)
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    notificationPresentationCompletionHandler = completionHandler;
    MSPush.didReceiveRemoteNotification(notification.request.content.userInfo)
  }

  @available(iOS 10.0, *)
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    notificationResponseCompletionHandler = completionHandler;
    MSPush.didReceiveRemoteNotification(response.notification.request.content.userInfo)
  }
}

#endif
