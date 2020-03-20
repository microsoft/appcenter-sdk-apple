// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Cocoa
import CoreLocation

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import AppCenterPush

enum StartupMode: Int {
    case appCenter
    case oneCollector
    case both
    case none
    case skip
}

@NSApplicationMain
@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate, MSCrashesDelegate, MSPushDelegate, CLLocationManagerDelegate {

  var rootController: NSWindowController!
  var locationManager: CLLocationManager = CLLocationManager()
    
  func applicationDidFinishLaunching(_ notification: Notification) {
    
    // Crashes Delegate.
    MSCrashes.setDelegate(self);
    MSCrashes.setUserConfirmationHandler({ (errorReports: [MSErrorReport]) in
      let alert: NSAlert = NSAlert()
      alert.messageText = "Sorry about that!"
      alert.informativeText = "Do you want to send an anonymous crash report so we can fix the issue?"
      alert.addButton(withTitle: "Always send")
      alert.addButton(withTitle: "Send")
      alert.addButton(withTitle: "Don't send")
      alert.alertStyle = .warning

      switch (alert.runModal()) {
      case .alertFirstButtonReturn:
        MSCrashes.notify(with: .always)
        break;
      case .alertSecondButtonReturn:
        MSCrashes.notify(with: .send)
        break;
      case .alertThirdButtonReturn:
        MSCrashes.notify(with: .dontSend)
        break;
      default:
        break;
      }
      return true
    })

    // Enable catching uncaught exceptions thrown on the main thread.
    UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])

    // Push Delegate.
    MSPush.setDelegate(self);

    // Set loglevel to verbose.
    MSAppCenter.setLogLevel(MSLogLevel.verbose)

    // Set custom log URL.
    let logUrl = UserDefaults.standard.string(forKey: kMSLogUrl)
    if logUrl != nil {
      MSAppCenter.setLogUrl(logUrl)
    }
    
    // Set location manager.
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer

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
                }
            }
        })
    }

    // Start AppCenter.
    let services = [MSAnalytics.self, MSCrashes.self, MSPush.self]
    let startTarget = StartupMode(rawValue: UserDefaults.standard.integer(forKey: kMSStartTargetKey))!
    let appSecret = UserDefaults.standard.string(forKey: kMSAppSecret) ?? kMSSwiftAppSecret
    switch startTarget {
    case .appCenter:
        MSAppCenter.start(appSecret, withServices: services)
        break
    case .oneCollector:
        MSAppCenter.start("target=\(kMSSwiftTargetToken)", withServices: services)
        break
    case .both:
        MSAppCenter.start("appsecret=\(appSecret);target=\(kMSSwiftTargetToken)", withServices: services)
        break
    case .none:
        MSAppCenter.start(withServices: services)
        break
    case .skip:
        break
    }
      
    // Set user id.
    let userId = UserDefaults.standard.string(forKey: kMSUserIdKey)
    if userId != nil {
      MSAppCenter.setUserId(userId)
    }

    AppCenterProvider.shared().appCenter = AppCenterDelegateSwift()

    initUI()

    overrideCountryCode()
  }

  func initUI() {
    let mainStoryboard = NSStoryboard.init(name: kMSMainStoryboardName, bundle: nil)
    rootController = mainStoryboard.instantiateController(withIdentifier: "rootController") as! NSWindowController
    rootController.showWindow(self)
    rootController.window?.makeKeyAndOrderFront(self)
  }

  func overrideCountryCode() {
    if CLLocationManager.locationServicesEnabled() {
      self.locationManager.startUpdatingLocation()
    }
    else {
      let alert : NSAlert = NSAlert()
      alert.messageText = "Location service is disabled"
      alert.informativeText = "Please enable location service on your Mac."
      alert.addButton(withTitle: "OK")
      alert.runModal()
    }
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
    }
    return attachments
  }

  // Push Delegate

  func push(_ push: MSPush!, didReceive pushNotification: MSPushNotification!) {

    // Bring any window to foreground if it was miniaturized.
    for window in NSApp.windows {
      if (window.isMiniaturized) {
        window.deminiaturize(self)
        break
      }
    }

    let title: String = pushNotification.title ?? ""
    var message: String = pushNotification.message ?? ""
    var customData: String = ""
    for item in pushNotification.customData {
      customData =  ((customData.isEmpty) ? "" : "\(customData), ") + "\(item.key): \(item.value)"
    }
    message =  message + ((customData.isEmpty) ? "" : "\n\(customData)")
    let alert: NSAlert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }
    
  // CLLocationManager Delegate
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    self.locationManager.stopUpdatingLocation()
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
