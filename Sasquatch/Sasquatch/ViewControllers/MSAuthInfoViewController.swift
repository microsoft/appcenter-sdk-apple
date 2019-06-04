// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSAuthInfoViewController: UIViewController, UITableViewDelegate {
  
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var tableView: UITableView!
  
  @IBAction func backButtonClicked(_ sender: Any) {
    self.presentingViewController?.dismiss(animated: true, completion: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.tableView.delegate = self
    self.tableView.setEditing(true, animated: false)
  }
}
