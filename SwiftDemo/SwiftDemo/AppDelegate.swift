/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

import UIKit

import MobileCenter
import MobileCenterAnalytics
import MobileCenterCrashes

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MSCrashesDelegate, UIAlertViewDelegate {

  var window: UIWindow?


  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    
    MSMobileCenter.start("7dfb022a-17b5-4d4a-9c75-12bc3ef5e6b7", withServices: [MSAnalytics.self, MSCrashes.self])

    // Analytics-API
//    MSAnalytics.trackEvent("Video clicked", withProperties: ["Category" : "Music", "FileName" : "favorite.avi"])
//    MSAnalytics.trackEvent("Video clicked")
//    MSAnalytics.setEnabled(false)
//    var enabled = MSAnalytics.isEnabled()

    // Crashes-API
    
    // Crashes Delegate
    MSCrashes.setUserConfirmationHandler({ (errorReports: [MSErrorReport]) in
      
      // Your code.
      // Present your UI to the user, e.g. an UIAlertView.
      UIAlertView.init(title: "Sorry we crashed!", message: "Do you want to send a Crash Report?", delegate: self, cancelButtonTitle: "No", otherButtonTitles:"Always send", "Send").show()
      
      return true
    })
    
    return true
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
    return true; // return true if the crash report should be processed, otherwise false.
  }
  
  func attachment(with crashes: MSCrashes!, for errorReport: MSErrorReport!) -> MSErrorAttachment! {
    let attachment = MSErrorAttachment.init(text: "TextAttachment", andBinaryData: (String("Hello World")?.data(using: String.Encoding.utf8))!, filename: "binary.txt", mimeType: "text/plain")
    return attachment
  }
  
  func crashes(_ crashes: MSCrashes!, willSend errorReport: MSErrorReport!) {
    
  }
  
  func crashes(_ crashes: MSCrashes!, didSucceedSending errorReport: MSErrorReport!) {
    
  }
  
  func crashes(_ crashes: MSCrashes!, didFailSending errorReport: MSErrorReport!, withError error: Error!) {
    
  }
  
  // UIAlertViewDelegate
  
  func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
    switch buttonIndex {
    case 0:
      MSCrashes.notify(with: MSUserConfirmation.dontSend)
      break
    case 1:
      MSCrashes.notify(with: MSUserConfirmation.always)
      break
    case 2:
      MSCrashes.notify(with: MSUserConfirmation.send)
      break
    default:
      break
    }
  }
}

