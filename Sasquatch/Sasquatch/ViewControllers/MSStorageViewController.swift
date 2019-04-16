// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSStorageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  enum StorageType: String {
    case App = "App"
    case User = "User"

    static let allValues = [App, User]
  }
  var identitySignIn = false
  static var AppDocuments = ["App1", "App2"]
  static var UserDocuments = ["User1", "User2", "User3"]
  static var AppDocumentContent = ["property1" : "property 1 string", "property2": 11] as [String : Any]
  static var UserDocumentsContent = ["property1": "property 1 string", "property2": 42, "property3": true] as [String : Any]

  private var storageTypePicker: MSEnumPicker<StorageType>?
  private var storageType = "App"
  
  @IBOutlet var backButton: UIButton!
  @IBOutlet var tableView: UITableView!
  @IBOutlet var storageTypeField: UITextField!

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.setEditing(true, animated: false)
    tableView.allowsSelectionDuringEditing = true
    identitySignIn = UserDefaults.standard.bool(forKey: "identitySignIn")
    
    initStoragePicker()
  }
  
  func initStoragePicker(){
    self.storageTypePicker = MSEnumPicker<StorageType> (
      textField: storageTypeField,
      allValues: StorageType.allValues,
      onChange: { index in
        self.storageType = (self.storageTypeField?.text)!
        if self.storageType == StorageType.User.rawValue && !self.identitySignIn {
          let alert = UIAlertController(title: "Error", message: "Please sign in to Identity firstly", preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.storageTypePicker?.doneClicked()
          }))
          self.present(alert, animated: true, completion: nil)
        } else {
          self.tableView.reloadData()
        }
    }
    )
    storageTypeField?.delegate = self.storageTypePicker
    storageTypeField?.tintColor = UIColor.clear
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if self.storageType == StorageType.User.rawValue && identitySignIn {
      return "User Documents List"
    } else if self.storageType == StorageType.App.rawValue {
      return "App Document List"
    }
    return nil
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if self.storageType == StorageType.App.rawValue {
      return MSStorageViewController.AppDocuments.count
    } else if self.storageType == StorageType.User.rawValue {
      if identitySignIn {
        return MSStorageViewController.UserDocuments.count + 1
      } else {
        return 0
      }
    }
    return 1
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cellIdentifier = "document"
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
    
    if self.storageType == StorageType.App.rawValue {
      cell.textLabel?.text = MSStorageViewController.AppDocuments[indexPath.row]
    } else if self.storageType == StorageType.User.rawValue {
      if indexPath.row == 0 {
        cell.textLabel?.text = "Add document"
      } else {
        cell.textLabel?.text = MSStorageViewController.UserDocuments[indexPath.row - 1]
      }
    }
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let cell = tableView.cellForRow(at: indexPath)
    if isInsertRow(indexPath) {
      self.performSegue(withIdentifier: "ShowDocumentDetails", sender: "")
    } else {
      self.performSegue(withIdentifier: "ShowDocumentDetails", sender: cell?.textLabel?.text)
    }
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if self.storageType == StorageType.User.rawValue {
      return true
    }
    return false
  }

  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if isInsertRow(indexPath) {
      return .insert
    } else if self.storageType == StorageType.User.rawValue {
      return .delete
    }
    return .none
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      MSStorageViewController.UserDocuments.remove(at: indexPath.row - 1)
      tableView.deleteRows(at: [indexPath], with: .automatic)
    } else if editingStyle == .insert {
      self.performSegue(withIdentifier: "ShowDocumentDetails", sender: "")
    }
  }

  func isInsertRow(_ indexPath: IndexPath) -> Bool {
    return self.storageType == StorageType.User.rawValue && indexPath.row == 0
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "ShowDocumentDetails" {
      let documentDetailsController = segue.destination as! MSDocumentDetailsViewController
      documentDetailsController.docmentType = self.storageType
      documentDetailsController.documentId = sender as! String
      if self.storageType == StorageType.App.rawValue {
        documentDetailsController.documentContent = MSStorageViewController.AppDocumentContent
      } else {
        documentDetailsController.documentContent = MSStorageViewController.UserDocumentsContent
      }
    }
  }

  

  @IBAction func backButtonClicked (_ sender: Any) {
    self.presentingViewController?.dismiss(animated: true, completion: nil)
  }
}
