// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import AppCenter
import AppCenterCrashes
import NotificationCenter
import UIKit

class ExtensionViewController: UIViewController, NCWidgetProviding, CrashesDelegate {
  @IBOutlet weak var crashLabel: UILabel!
  @IBOutlet weak var extensionLabel: UILabel!
  @IBOutlet weak var attachementsSwitch: UISwitch!

  var selectedCrash = 0
  var crashes = MSCrash.allCrashes() as! [MSCrash]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    pokeAllCrashes()
    crashes = MSCrash.allCrashes() as! [MSCrash]
    crashLabel.text = crashes[0].title
    let dateString = DateFormatter.localizedString(from: Date.init(), dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.medium)
    extensionLabel.text = "Run #\(dateString)"
    AppCenter.logLevel = .verbose
    Crashes.delegate = self
    AppCenter.start(withAppSecret: "238d7788-8e63-478f-a747-33444bdadbda", services: [Crashes.self])
  }
  
  func attachments(with crashes: Crashes, for errorReport: ErrorReport) -> [ErrorAttachmentLog] {
    if (attachementsSwitch.isOn) {
      let attachment1 = ErrorAttachmentLog.attachment(withText: "Hello world!", filename: "hello.txt")
      let attachment2 = ErrorAttachmentLog.attachment(withBinary: "Fake image".data(using: String.Encoding.utf8), filename: nil, contentType: "image/jpeg")
      return [attachment1!, attachment2!]
    }
    return [];
  }
  
  @IBAction func onNext(_ sender: Any) {
    selectedCrash = selectedCrash + 1;
    if (selectedCrash >= crashes.count) {
        selectedCrash = 0
    }
    crashLabel.text = crashes[selectedCrash].title
  }
  
  private func pokeAllCrashes() {
    var count = UInt32(0)
    let classList = objc_copyClassList(&count)
    let classes = UnsafeBufferPointer(start: classList, count: Int(count))
    MSCrash.removeAllCrashes()
    for i in 0..<Int(count){
      let className: AnyClass = classes[i]
      if class_getSuperclass(className) == MSCrash.self && className != MSCrash.self {
        MSCrash.register((className as! MSCrash.Type).init())
      }
    }
  }
  
  @IBAction func crashMe(_ sender: Any) {
    let crash = crashes[selectedCrash]
    crash.crash()
  }
  
  func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
    completionHandler(NCUpdateResult.newData)
  }
}
