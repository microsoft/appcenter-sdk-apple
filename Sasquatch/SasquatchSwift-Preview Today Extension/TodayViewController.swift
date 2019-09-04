// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit
import NotificationCenter
import AppCenter
import AppCenterCrashes

class TodayViewController: UIViewController, NCWidgetProviding {
  
  @IBOutlet weak var extensionLabel: UILabel!
  
  var didStartAppCenter = false;
  override func viewDidLoad() {
    
    super.viewDidLoad()
    extensionLabel.text = "Run #\(UUID().uuidString)"
    if (!didStartAppCenter){
      MSAppCenter.setLogLevel(.verbose);
      MSAppCenter.start("238d7788-8e63-478f-a747-33444bdadbda", withServices: [MSCrashes.self])
      didStartAppCenter = true;
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
