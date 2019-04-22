// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSStorageViewController: UITableViewController {

  enum StorageType: String {
    case App = "App"
    case User = "User"

    static let allValues = [App, User]
  }
  private var AppDocuments = ["App1","App2","App3"]
  private var UserDocuments = ["User1","User2","User3","User4","User5"]
  private var storageTypePicker: MSEnumPicker<StorageType>?
  private var storageType = "App"

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 3
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 1 {
      return "Storage Type"
    } else if section == 2 {
      if(self.storageType == StorageType.User.rawValue) {
        return "User Documents List"
      } else {
        return "App Document List"
      }
    }
    return nil
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 2 {
      if(self.storageType == StorageType.App.rawValue) {
        return AppDocuments.count
      } else if (self.storageType == StorageType.User.rawValue) {
        return UserDocuments.count
      }
    }
    return 1
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cellIdentifier = "back"
    if indexPath.section == 1 {
      cellIdentifier = "storagetype"
    } else if indexPath.section == 2 {
      cellIdentifier = "document"
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
    if indexPath.section == 0 {
      let backButton: UIButton? = cell.getSubview()
      backButton?.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
    } else if indexPath.section == 1 {
      let storageTypeField: UITextField? = cell.getSubview()
      self.storageTypePicker = MSEnumPicker<StorageType> (
        textField: storageTypeField,
        allValues: StorageType.allValues,
        onChange: { index in
          self.storageType = (storageTypeField?.text)!
          self.tableView.reloadSections([2], with: .none)
        }
      )
      storageTypeField?.delegate = self.storageTypePicker
      storageTypeField?.tintColor = UIColor.clear
    } else if indexPath.section == 2 {
      cell.accessoryType = .disclosureIndicator
      if (self.storageType == StorageType.App.rawValue) {
        cell.textLabel?.text = AppDocuments[indexPath.row]
      } else if (self.storageType == StorageType.User.rawValue) {
        cell.textLabel?.text = UserDocuments[indexPath.row]
      }
    }
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let cell = tableView.cellForRow(at: indexPath)
    if indexPath.section == 2 {
      let documentTitle = cell?.textLabel?.text
      self.performSegue(withIdentifier: "ShowDocumentDetails", sender: documentTitle)
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "ShowDocumentDetails" {
      let documentDetailsController = segue.destination as! MSDocumentDetailsViewController
      documentDetailsController.documentTitle = sender as? String
    }
  }

  @objc func backButtonClicked (_ sender: Any) {
    self.presentingViewController?.dismiss(animated: true, completion: nil)
  }
}
