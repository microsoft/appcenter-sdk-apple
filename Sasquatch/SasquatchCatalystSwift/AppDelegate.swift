// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import CoreLocation
import MobileCoreServices
import Photos
import UIKit

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
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

    // Start App Center SDK.
    let services = [MSAnalytics.self, MSCrashes.self]
    let appSecret = UserDefaults.standard.string(forKey: kMSAppSecret) ?? kMSSwiftAppSecret
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
    //todo:PHAsset.fetchAssets is not supported on Catalyst
    let referenceUrl = UserDefaults.standard.url(forKey: "fileAttachment")
    if referenceUrl != nil {
#if TARGET_OS_IOS
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

