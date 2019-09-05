// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit
import NotificationCenter
import AppCenter
import AppCenterCrashes

class TodayViewController: UIViewController, NCWidgetProviding, UIPickerViewDataSource, UIPickerViewDelegate {
  
  @IBOutlet weak var extensionLabel: UILabel!
  @IBOutlet weak var crashPickerView: UIPickerView!
 
  var didStartAppCenter = false;
  var crashes = MSCrash.allCrashes() as! [MSCrash]
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1;
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return crashes.count;
  }
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
    pokeAllCrashes()
    
    var crashes = MSCrash.allCrashes() as! [MSCrash]

    crashPickerView.reloadComponent(0);
    
    extensionLabel.text = "Run #\(UUID().uuidString)"
    if (!didStartAppCenter) {
      MSAppCenter.setLogLevel(.verbose);
      MSAppCenter.start("238d7788-8e63-478f-a747-33444bdadbda", withServices: [MSCrashes.self])
      didStartAppCenter = true;
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return String(crashes[row]);
  }
  
  private func pokeAllCrashes() {
    var count = UInt32(0)
    let classList = objc_copyClassList(&count)
    MSCrash.removeAllCrashes()
    for i in 0..<Int(count){
      let className: AnyClass = classList![i]
      if class_getSuperclass(className) == MSCrash.self && className != MSCrash.self {
        MSCrash.register((className as! MSCrash.Type).init())
      }
    }
  }
  
  @IBAction func crashMe(_ sender: Any) {
    let buf: UnsafeMutablePointer<UInt>? = nil;
    buf![1] = 1;
  }
  
  func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
    completionHandler(NCUpdateResult.newData)
  }
}
