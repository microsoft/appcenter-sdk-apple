// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Cocoa

class EventFilterViewController: NSViewController {

  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!
  private var eventFilterStarted = false

  @IBOutlet weak var setEnabledButton: NSButton!

  @IBAction func setEnabled(_ sender: NSButton) {
    if !eventFilterStarted {
      appCenter.startEventFilterService()
      eventFilterStarted = true
    }
    appCenter.setEventFilterEnabled(sender.state == .on)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setEnabledButton?.state = appCenter.isEventFilterEnabled() ? .on : .off
  }
}
