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
import UserNotifications

enum StartupMode: Int {
  case APPCENTER
  case ONECOLLECTOR
  case BOTH
  case NONE
  case SKIP
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CrashesDelegate, CLLocationManagerDelegate {

  private var notificationPresentationCompletionHandler: Any?
  private var notificationResponseCompletionHandler: Any?
  private var locationManager : CLLocationManager = CLLocationManager()

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    Crashes.delegate = self
#if canImport(AppCenterDistribute)
    Distribute.delegate = self
#endif
    AppCenter.logLevel = LogLevel.verbose

    // Set max storage size.
    let storageMaxSize = UserDefaults.standard.object(forKey: kMSStorageMaxSizeKey) as? Int
    if storageMaxSize != nil {
      AppCenter.setMaxStorageSize(storageMaxSize!, completionHandler: { success in
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
      AppCenter.logUrl = logUrl
    }
#if canImport(AppCenterDistribute)
    if let updateTrackValue = UserDefaults.standard.value(forKey: kMSUpdateTrackKey) as? Int,
       let updateTrack = UpdateTrack(rawValue: updateTrackValue) {
        Distribute.updateTrack = updateTrack
    }
    if UserDefaults.standard.bool(forKey: kSASAutomaticCheckForUpdateDisabledKey) {
        Distribute.disableAutomaticCheckForUpdate()
    }
#endif

    // Start App Center SDK.
    var services = [Analytics.self, Crashes.self]
#if canImport(AppCenterDistribute)
    services.append(Distribute.self)
#endif
    let appSecret = UserDefaults.standard.string(forKey: kMSAppSecret) ?? kMSSwiftCombinedAppSecret
    let startTarget = StartupMode(rawValue: UserDefaults.standard.integer(forKey: kMSStartTargetKey))!
    let latencyTimeValue = UserDefaults.standard.integer(forKey: kMSTransmissionIterval);
    Analytics.transmissionInterval = UInt(latencyTimeValue);
    switch startTarget {
    case .APPCENTER:
      AppCenter.start(withAppSecret: appSecret, services: services)
      break
    case .ONECOLLECTOR:
      AppCenter.start(withAppSecret: "target=\(kMSSwiftTargetToken)", services: services)
      break
    case .BOTH:
      AppCenter.start(withAppSecret: "\(appSecret);target=\(kMSSwiftTargetToken)", services: services)
      break
    case .NONE:
      AppCenter.start(services: services)
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
      AppCenter.userId = userId;
    }

    // Crashes Delegate.
    Crashes.userConfirmationHandler = ({ (errorReports: [ErrorReport]) in

      // Show a dialog to the user where they can choose if they want to update.
      let alertController = UIAlertController(title: "Sorry about that!",
              message: "Do you want to send an anonymous crash report so we can fix the issue?",
              preferredStyle: .alert)

      // Add a "Don't send"-Button and call the notifyWithUserConfirmation-callback with UserConfirmation.dontSend
      alertController.addAction(UIAlertAction(title: "Don't send", style: .cancel) { _ in
        Crashes.notify(with: .dontSend)
      })

      // Add a "Send"-Button and call the notifyWithUserConfirmation-callback with UserConfirmation.send
      alertController.addAction(UIAlertAction(title: "Send", style: .default) { _ in
        Crashes.notify(with: .send)
      })

      // Add a "Always send"-Button and call the notifyWithUserConfirmation-callback with UserConfirmation.always
      alertController.addAction(UIAlertAction(title: "Always send", style: .default) { _ in
        Crashes.notify(with: .always)
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
    return Distribute.open(url);
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

  func crashes(_ crashes: Crashes, shouldProcess errorReport: ErrorReport) -> Bool {

    // return true if the crash report should be processed, otherwise false.
    return true
  }

  func crashes(_ crashes: Crashes!, willSend errorReport: ErrorReport!) {
  }

  func crashes(_ crashes: Crashes!, didSucceedSending errorReport: ErrorReport!) {
  }

  func crashes(_ crashes: Crashes, didFailSending errorReport: ErrorReport, withError error: Error?) {
  }

  func attachments(with crashes: Crashes, for errorReport: ErrorReport) -> [ErrorAttachmentLog] {
    var attachments = [ErrorAttachmentLog]()

    // Text attachment.
    let text = UserDefaults.standard.string(forKey: "textAttachment") ?? ""
    if !text.isEmpty {
        let textAttachment = ErrorAttachmentLog.attachment(withText: text, filename: "user.log")!
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
          let binaryAttachment = ErrorAttachmentLog.attachment(withBinary: imageData, filename: dataUTI, contentType: mime! as String)!
          attachments.append(binaryAttachment)
          print("Add binary attachment with \(imageData?.count ?? 0) bytes")
        })
      }
#else
      do {
        let data = try Data(contentsOf: referenceUrl!)
        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, referenceUrl!.pathExtension as NSString, nil)?.takeRetainedValue()
        let mime = UTTypeCopyPreferredTagWithClass(uti!, kUTTagClassMIMEType)?.takeRetainedValue() as NSString?
        let binaryAttachment = ErrorAttachmentLog.attachment(withBinary: data, filename: referenceUrl?.lastPathComponent, contentType: mime! as String)!
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
        AppCenter.countryCode = placemarks?.first?.isoCountryCode
      }
    }
  }

  func locationManager(_ Manager: CLLocationManager, didFailWithError error: Error) {
    print("Failed to find user's location: \(error.localizedDescription)")
  }

}

#if canImport(AppCenterDistribute)

extension AppDelegate: DistributeDelegate {
  func distribute(_ distribute: Distribute, releaseAvailableWith details: ReleaseDetails) -> Bool {
    if UserDefaults.standard.bool(forKey: kSASCustomizedUpdateAlertKey) {

      // Show a dialog to the user where they can choose if they want to update.
      let alertController = UIAlertController(title: NSLocalizedString("distribute_alert_title", tableName: "Sasquatch", comment: ""),
              message: NSLocalizedString("distribute_alert_message", tableName: "Sasquatch", comment: ""),
              preferredStyle: .alert)

      // Add a "Yes"-Button and call the notifyUpdateAction-callback with .update
      alertController.addAction(UIAlertAction(title: NSLocalizedString("distribute_alert_yes", tableName: "Sasquatch", comment: ""), style: .cancel) { _ in
        Distribute.notify(.update)
      })

      // Add a "No"-Button and call the notifyUpdateAction-callback with .postpone
      alertController.addAction(UIAlertAction(title: NSLocalizedString("distribute_alert_no", tableName: "Sasquatch", comment: ""), style: .default) { _ in
        Distribute.notify(.postpone)
      })

      // Show the alert controller.
      self.window?.rootViewController?.present(alertController, animated: true)
      return true
    }
    return false
  }
  
  func distributeNoReleaseAvailable(_ distribute: Distribute) {
    NSLog("distributeNoReleaseAvailable invoked");
    let alert = UIAlertController(title: nil, message: "No updates available", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    self.window?.rootViewController?.present(alert, animated: true)
  }

  func distributeWillExitApp(_ distribute: Distribute) {
    print("distributeWillExitApp callback invoked");
  }
}

#endif
