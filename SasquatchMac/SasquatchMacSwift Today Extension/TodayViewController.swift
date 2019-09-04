
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
import Cocoa
import NotificationCenter
import AppCenter
import AppCenterCrashes
class TodayViewController: NSViewController, NCWidgetProviding {
    @IBOutlet weak var extensionLabel: NSTextField!
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("TodayViewController")
    }
    var didStartAppCenter = false;
    override func viewDidLoad() {
        
        super.viewDidLoad()
        extensionLabel.stringValue = "Run #\(UUID().uuidString)"
        if (!didStartAppCenter){
            MSAppCenter.setLogLevel(.verbose);
            MSAppCenter.start("aca58ea0-d791-4409-989d-2efec0283800", withServices: [MSCrashes.self])
            didStartAppCenter = true;
        }
    }
    
    @IBAction func crashMe(_ sender: Any) {
        let buf: UnsafeMutablePointer<UInt>? = nil;
        buf![1] = 1;
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(.noData)
    }
}
