// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSStorageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, AppCenterProtocol {
  
  var appCenter: AppCenterDelegate!
  enum StorageType: String {
    case App = "App"
    case User = "User"
    
    static let allValues = [App, User]
  }
  var allDocuments: MSPaginatedDocuments<TestDocument> = MSPaginatedDocuments()
  var loadMoreStatus = false
  var identitySignIn = false
  static var AppDocuments: [MSDocumentWrapper<TestDocument>] = []
  static var UserDocuments: [MSDocumentWrapper<TestDocument>] = []
  private var storageTypePicker: MSEnumPicker<StorageType>?
  private var storageType = StorageType.App.rawValue
  
  @IBOutlet var backButton: UIButton!
  @IBOutlet var tableView: UITableView!
  @IBOutlet var storageTypeField: UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.setEditing(true, animated: false)
    tableView.allowsSelectionDuringEditing = true
    identitySignIn = UserDefaults.standard.bool(forKey: kMSUserIdentity)
    initStoragePicker()
    loadAppFiles()
  }
  
  func loadAppFiles() {
    self.appCenter.listDocumentsWithPartition("READONLY", documentType: TestDocument.self, completionHandler: { (documents) in
      self.allDocuments = documents;
      MSStorageViewController.AppDocuments = documents.currentPage()?.items ?? []
      DispatchQueue.main.async {
        self.tableView.isHidden = false
        self.tableView.reloadData()
      }
    })
  }
  
  func loadUserFiles() {
    self.appCenter.listDocumentsWithPartition("USER", documentType: TestDocument.self, completionHandler: { (documents) in
      self.allDocuments = documents;
      MSStorageViewController.UserDocuments = documents.currentPage()?.items ?? []
      DispatchQueue.main.async {
        self.tableView.isHidden = false
        self.tableView.reloadData()
      }
    })
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let currentOffset = scrollView.contentOffset.y
    let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
    let deltaOffset = maximumOffset - currentOffset
    
    if deltaOffset <= 0 {
      loadMore()
    }
  }
  
  func loadMore() {
    if (!loadMoreStatus && self.allDocuments.hasNextPage()) {
      self.loadMoreStatus = true
      DispatchQueue.global().async() {
        self.allDocuments.nextPage(completionHandler: { page in
          if self.storageType == StorageType.User.rawValue && self.identitySignIn {
            MSStorageViewController.UserDocuments += page?.items ?? []
          } else {
            MSStorageViewController.AppDocuments += page?.items ?? []
          }
          DispatchQueue.main.sync {
            self.tableView.isHidden = false
            self.tableView.reloadData()
            self.loadMoreStatus = false
          }
        })
      }
    }
  }
  
  func upload()  {
    DispatchQueue.main.sync {
      self.tableView.isHidden = false
      self.tableView.reloadData()
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableView.reloadData()
  }
  
  func initStoragePicker(){
    let alert = UIAlertController(title: "Error", message: "Please sign in to Identity first", preferredStyle: .alert)
    self.storageTypePicker = MSEnumPicker<StorageType> (
      textField: storageTypeField,
      allValues: StorageType.allValues,
      onChange: { index in
        self.storageType = (self.storageTypeField?.text)!
        if self.storageType == StorageType.User.rawValue && !self.identitySignIn {
          alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.storageTypePicker?.doneClicked()
          }))
          self.present(alert, animated: true, completion: nil)
        } else if (self.storageType == StorageType.User.rawValue) {
          self.loadUserFiles()
        } else {
          self.loadAppFiles()
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
      cell.textLabel?.text = MSStorageViewController.AppDocuments[indexPath.row].documentId
    } else if self.storageType == StorageType.User.rawValue {
      if indexPath.row == 0 {
        cell.textLabel?.text = "Add document"
      } else {
        cell.textLabel?.text = MSStorageViewController.UserDocuments[indexPath.row - 1].documentId
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
// uncommit when work with real data
//      appCenter.deleteDocumentWithPartition(StorageType.User.rawValue, documentId: MSStorageViewController.UserDocuments[indexPath.row - 1].documentId)
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
      documentDetailsController.documentType = self.storageType
      documentDetailsController.documentId = sender as? String
      documentDetailsController.documentTimeToLive = sender as? String
      if self.storageType == StorageType.App.rawValue {
        documentDetailsController.documentContent = MSStorageViewController.AppDocuments
      } else {
        documentDetailsController.documentContent = MSStorageViewController.UserDocuments
      }
    }
  }
  
  @IBAction func backButtonClicked (_ sender: Any) {
    self.presentingViewController?.dismiss(animated:true, completion: nil)
  }
}
