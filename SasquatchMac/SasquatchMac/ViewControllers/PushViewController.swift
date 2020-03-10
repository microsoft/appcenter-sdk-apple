// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Cocoa

class PushViewController: NSViewController {

  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!

  @IBOutlet weak var setEnabledButton: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad();
  }

  override func viewWillAppear() {
    setEnabledButton?.state = NSControl.StateValue(rawValue: appCenter.isPushEnabled() ? 1 : 0)
  }
  
  @IBAction func setEnabled(_ sender: NSButton) {
    appCenter.setPushEnabled(sender.state.rawValue == 1)
    sender.state = NSControl.StateValue(rawValue: appCenter.isPushEnabled() ? 1 : 0)
  }
}
