// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import AppCenter
import AppCenterCrashes
import Cocoa
import NotificationCenter

class TodayViewController: NSViewController, NCWidgetProviding {
  
    @IBOutlet weak var popupButton: NSPopUpButton!
    @IBOutlet weak var extensionLabel: NSTextField!
    var crashes = [MSCrash]()
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("TodayViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dateString = DateFormatter.localizedString(from: Date.init(), dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.medium)
        extensionLabel.stringValue = "Run #\(dateString)"
        MSAppCenter.setLogLevel(.verbose)
        MSAppCenter.start("aca58ea0-d791-4409-989d-2efec0283800", withServices: [MSCrashes.self])
        crashes = CrashLoader.loadAllCrashes(withCategories: false) as! [MSCrash]
        popupButton.menu?.removeAllItems()
        for (index, crash) in crashes.enumerated() {
            popupButton.menu?.addItem(NSMenuItem(title: crash.title, action: nil, keyEquivalent: "\(index)"))
        }
    }
    
    @IBAction func crashMe(_ sender: Any) {
        let selectedCrashIndex = popupButton.indexOfSelectedItem
        crashes[selectedCrashIndex].crash()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(.noData)
    }
}
