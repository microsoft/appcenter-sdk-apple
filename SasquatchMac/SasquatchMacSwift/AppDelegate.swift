import Cocoa

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import AppCenterPush

@NSApplicationMain
@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate, MSCrashesDelegate, MSPushDelegate {

  var rootController: NSWindowController!

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
      alert.alertStyle = NSWarningAlertStyle

      switch (alert.runModal()) {
      case NSAlertFirstButtonReturn:
        MSCrashes.notify(with: .always)
        break;
      case NSAlertSecondButtonReturn:
        MSCrashes.notify(with: .send)
        break;
      case NSAlertThirdButtonReturn:
        MSCrashes.notify(with: .dontSend)
        break;
      default:
        break;
      }
      return true
    })

    // Push Delegate.
    MSPush.setDelegate(self);

    MSAppCenter.setLogLevel(MSLogLevel.verbose)

    // Set user id.
    let userId = UserDefaults.standard.string(forKey: "userId")
    if userId != nil {
      MSAppCenter.setUserId(userId)
    }

    // Start AppCenter.
    MSAppCenter.start("7e873482-108f-4609-8ef2-c4cebd7418c0", withServices : [ MSAnalytics.self, MSCrashes.self, MSPush.self ])

    AppCenterProvider.shared().appCenter = AppCenterDelegateSwift()

    initUI()
  }

  func initUI() {
    let mainStoryboard = NSStoryboard.init(name: kMSMainStoryboardName, bundle: nil)
    rootController = mainStoryboard.instantiateController(withIdentifier: "rootController") as! NSWindowController
    rootController.showWindow(self)
    rootController.window?.makeKeyAndOrderFront(self)
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
}
