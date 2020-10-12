// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

@objc(MSAnalyticsPropertyTableViewCell) class MSAnalyticsPropertyTableViewCell: UITableViewCell {
  @IBOutlet weak var keyField: UITextField!
  @IBOutlet weak var valueField: UITextField!
  var currentTarget: String = ""

  @IBAction func dismissKeyboard(_ sender: UITextField!) {
    sender.resignFirstResponder()
  }

}
