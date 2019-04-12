// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSDocumentDetailsViewController: UIViewController {

  var documentTitle: String?

  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var documentTitleField: UITextField!

  override func viewDidLoad() {
    super.viewDidLoad()
    documentTitleField.text = documentTitle
  }

  @IBAction func backButtonClicked(_ sender: Any) {
    self.presentingViewController?.dismiss(animated: true, completion: nil)
  }
}
