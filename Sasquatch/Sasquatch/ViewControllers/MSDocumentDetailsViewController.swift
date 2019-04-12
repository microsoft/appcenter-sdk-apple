// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSDocumentDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  var documentType: String?
  var documentId: String?
  var userDocumentAddPropertiesSection: EventPropertiesTableSection!
  var documentContent: [String: Any]?
  private let kUserDocumentAddPropertiesSectionIndex: Int = 0

  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var docIdField: UITextField!
  @IBOutlet weak var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    docIdField.text = documentId
    docIdField.placeholder = "Please input an user document id"
    self.tableView.delegate = self
    self.tableView.dataSource = self
    self.tableView.setEditing(true, animated: false)
  }

  override func loadView() {
    super.loadView()
    if documentType == "User" && documentId!.isEmpty {
      docIdField.isEnabled = true
    }
    userDocumentAddPropertiesSection = EventPropertiesTableSection(tableSection: 0, tableView: self.tableView)
  }

  @IBAction func backButtonClicked(_ sender: Any) {
    self.presentingViewController?.dismiss(animated: true, completion: nil)
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    if documentType == "User" && !(documentId!.isEmpty) {
      return 3
    } else if documentType == "User" && documentId!.isEmpty {
      return 2
    }
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if documentType == "User" && section == kUserDocumentAddPropertiesSectionIndex {
      return userDocumentAddPropertiesSection.tableView(tableView, numberOfRowsInSection: section)
    } else if documentType == "User" && section == 1 {
      return 1
    }
    return documentContent?.count ?? 0
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if documentType == "User" && indexPath.section == kUserDocumentAddPropertiesSectionIndex {
      return userDocumentAddPropertiesSection.tableView(tableView, canEditRowAt:indexPath)
    } else if documentType == "User" {
      return true
    }
    return false
  }

  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if documentType == "User" && indexPath.section == kUserDocumentAddPropertiesSectionIndex {
      return userDocumentAddPropertiesSection.tableView(tableView, editingStyleForRowAt: indexPath)
    } else if documentType == "User" && indexPath.section == 2 {
      return .delete
    }
    return .none
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if documentType == "User" && indexPath.section == kUserDocumentAddPropertiesSectionIndex {
      userDocumentAddPropertiesSection.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
    } else if documentType == "User" && indexPath.section == 2 {
      let index = documentContent!.index(documentContent!.startIndex, offsetBy: indexPath.row)
      documentContent!.remove(at: index)
      MSStorageViewController.UserDocumentsContent.remove(at: index)
      tableView.deleteRows(at: [indexPath], with: .automatic)
    }
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if documentType == "User" && indexPath.section == kUserDocumentAddPropertiesSectionIndex && userDocumentAddPropertiesSection.isInsertRow(indexPath) {
      self.tableView(tableView, commit: .insert, forRowAt: indexPath)
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if documentType == "User" && indexPath.section == kUserDocumentAddPropertiesSectionIndex {
      return userDocumentAddPropertiesSection.tableView(tableView, cellForRowAt:indexPath)
    } else if documentType == "User" && indexPath.section == 1 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "save", for: indexPath)
      let saveButton: UIButton? = cell.getSubview()
      saveButton?.addTarget(self, action: #selector(saveButtonClicked), for: .touchUpInside)
      return cell
    } else{
      let cell = tableView.dequeueReusableCell(withIdentifier: "property", for: indexPath)
      cell.textLabel?.text = "\(Array(documentContent!.keys)[indexPath.row]) : \(Array(documentContent!.values)[indexPath.row])"
      return cell
    }
  }

  func saveButtonClicked(_ sender: UIButton) {
    if docIdField.isEnabled && !((docIdField.text?.isEmpty)!) {
      MSStorageViewController.UserDocuments.append(docIdField.text!)
    }
    if !((docIdField.text?.isEmpty)!) {
      let docProperties = userDocumentAddPropertiesSection.typedProperties
      for property in docProperties {
        switch property.type {
        case .String:
          MSStorageViewController.UserDocumentsContent.updateValue(property.value as! String, forKey: property.key)
        case .Double:
          MSStorageViewController.UserDocumentsContent.updateValue(property.value as! Double, forKey: property.key)
        case .Long:
          MSStorageViewController.UserDocumentsContent.updateValue(property.value as! Int64, forKey: property.key)
        case .Boolean:
          MSStorageViewController.UserDocumentsContent.updateValue(property.value as! Bool, forKey: property.key)
        case .DateTime:
          MSStorageViewController.UserDocumentsContent.updateValue(property.value as! Date, forKey: property.key)
        }
      }
    }
    self.presentingViewController?.dismiss(animated: true, completion: nil)
  }
}
