// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSDataViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, AppCenterProtocol {
  
  var appCenter: AppCenterDelegate!
  var alert: UIAlertController!
  enum DocumentType: String {
    case App = "App"
    case User = "User"
    
    static let allValues = [App, User]
  }
  var allDocuments: MSPaginatedDocuments = MSPaginatedDocuments()
  var loadMoreStatus = false
  var authSignIn = false
  static var AppDocuments: [MSDocumentWrapper] = []
  static var UserDocuments: [MSDocumentWrapper] = []
  private var documentTypePicker: MSEnumPicker<DocumentType>?
  private var documentType = DocumentType.App.rawValue
  var indicator = UIActivityIndicatorView()
  
  @IBOutlet var backButton: UIButton!
  @IBOutlet var tableView: UITableView!
  @IBOutlet var documentTypeField: UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.setEditing(true, animated: false)
    tableView.allowsSelectionDuringEditing = true
    authSignIn = UserDefaults.standard.bool(forKey: kMSUserIdentity)
    buildAlertDialog()
    initDocumentPicker()
    activityIndicator()
    loadAppFiles()
  }
  
  func loadAppFiles() {
    startAnimation()
    self.appCenter.listDocumentsWithPartition("readonly", documentType: MSDictionaryDocument.self, completionHandler: { (documents) in
      self.allDocuments = documents;
      MSDataViewController.AppDocuments = documents.currentPage().items ?? []
      DispatchQueue.main.async {
        self.indicator.stopAnimating()
        self.tableView.isHidden = false
        self.tableView.reloadData()
      }
    })
  }
  
  func loadUserFiles() {
    startAnimation()
    self.appCenter.listDocumentsWithPartition("user", documentType: MSDictionaryDocument.self, completionHandler: { (documents) in
      self.allDocuments = documents;
      MSDataViewController.UserDocuments = documents.currentPage().items ?? []
      DispatchQueue.main.async {
        self.indicator.stopAnimating()
        self.tableView.isHidden = false
        self.tableView.reloadData()
      }
    })
  }
  
  func startAnimation() {
    DispatchQueue.main.async {
      self.indicator.startAnimating()
    }
  }
  
  func activityIndicator() {
    indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    indicator.center = self.view.center
    indicator.backgroundColor = UIColor.white
    indicator.hidesWhenStopped = true
    self.view.addSubview(indicator)
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
    if (!loadMoreStatus && self.allDocuments.hasNextPage()){
      self.loadMoreStatus = true
      DispatchQueue.global().async() {
        self.allDocuments.nextPage(completionHandler: { page in
          if self.documentType == DocumentType.User.rawValue && self.authSignIn {
            MSDataViewController.UserDocuments += page.items ?? []
          } else {
            MSDataViewController.AppDocuments += page.items ?? []
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
  
  func initDocumentPicker(){
    self.documentTypePicker = MSEnumPicker<DocumentType> (
      textField: documentTypeField,
      allValues: DocumentType.allValues,
      onChange: { index in
        if self.documentTypeField?.text == DocumentType.User.rawValue && !self.authSignIn {
          self.present(self.alert, animated: true, completion: nil)
          self.documentTypeField?.text = DocumentType.App.rawValue
        } else {
          if (self.documentTypeField?.text == DocumentType.User.rawValue) {
            self.loadUserFiles()
          } else {
            self.loadAppFiles()
          }
          self.documentType = (self.documentTypeField?.text)!
        }
    })
    documentTypeField?.delegate = self.documentTypePicker
    documentTypeField?.tintColor = UIColor.clear
  }
  
  func buildAlertDialog() {
    self.alert = UIAlertController(title: "Error", message: "Please sign in to Auth first", preferredStyle: .alert)
    self.alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
      self.documentTypePicker?.doneClicked()
    }))
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if self.documentType == DocumentType.User.rawValue && authSignIn {
      return "User Documents List"
    } else if self.documentType == DocumentType.App.rawValue {
      return "App Document List"
    }
    return nil
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if self.documentType == DocumentType.App.rawValue {
      return MSDataViewController.AppDocuments.count
    } else if self.documentType == DocumentType.User.rawValue {
      if authSignIn {
        return MSDataViewController.UserDocuments.count + 1
      } else {
        return 0
      }
    }
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cellIdentifier = "document"
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
    if self.documentType == DocumentType.App.rawValue {
      cell.textLabel?.text = MSDataViewController.AppDocuments[indexPath.row].documentId
    } else if self.documentType == DocumentType.User.rawValue {
      if indexPath.row == 0 {
        cell.textLabel?.text = "Add document"
      } else {
        let index = indexPath.row == 0 ? 0 : indexPath.row - 1
        cell.textLabel?.text = MSDataViewController.UserDocuments[index].documentId
      }
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if isInsertRow(indexPath) {
      self.performSegue(withIdentifier: "ShowDocumentDetails", sender: "")
    } else {
      if self.documentType == DocumentType.App.rawValue {
        self.performSegue(withIdentifier: "ShowDocumentDetails", sender: MSDataViewController.AppDocuments[indexPath.row])
      } else {
        let index = indexPath.row == 0 ? 0 : indexPath.row - 1
        self.performSegue(withIdentifier: "ShowDocumentDetails", sender: MSDataViewController.UserDocuments[index])
      }
    }
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if self.documentType == DocumentType.User.rawValue {
      return true
    }
    return false
  }
  
  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    if isInsertRow(indexPath) {
      return .insert
    } else if self.documentType == DocumentType.User.rawValue {
      return .delete
    }
    return .none
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    let index = indexPath.row == 0 ? 0 : indexPath.row - 1
    if editingStyle == .delete {
      appCenter.deleteDocumentWithPartition(DocumentType.User.rawValue.lowercased(), documentId: MSDataViewController.UserDocuments[index].documentId)
      MSDataViewController.UserDocuments.remove(at: index)
      tableView.deleteRows(at: [indexPath], with: .automatic)
    } else if editingStyle == .insert {
      if(index != 0) {
        self.performSegue(withIdentifier: "ShowDocumentDetails", sender: MSDataViewController.UserDocuments[index])
      } else {
        self.performSegue(withIdentifier: "ShowDocumentDetails", sender: "")
      }
    }
  }

  func isInsertRow(_ indexPath: IndexPath) -> Bool {
    return self.documentType == DocumentType.User.rawValue && indexPath.row == 0
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let documentDetailsController = segue.destination as! MSDocumentDetailsViewController
    if segue.identifier == "ShowDocumentDetails" {
        documentDetailsController.appCenter = appCenter
      if(sender as? String == "") {
        documentDetailsController.documentType = DocumentType.User.rawValue
      } else {
        documentDetailsController.documentType = self.documentType
        documentDetailsController.documentId = (sender as? MSDocumentWrapper)?.documentId
        documentDetailsController.documentTimeToLive = "Default"
        documentDetailsController.documentContent = sender as? MSDocumentWrapper
      }
    }
  }
  
  @IBAction func backButtonClicked (_ sender: Any) {
    self.presentingViewController?.dismiss(animated:true, completion: nil)
  }
  
  @IBAction func saveDocument(_ segue: UIStoryboardSegue) {
    guard let documentDetailsController = segue.source as? MSDocumentDetailsViewController, let documentId = documentDetailsController.documentId, let documentToSave = documentDetailsController.document, let writeOptions = documentDetailsController.writeOptions else {
        return
    }
    indicator.startAnimating()
    if (documentDetailsController.replaceDocument) {
      self.appCenter.replaceDocumentWithPartition(MSDataViewController.DocumentType.User.rawValue.lowercased(), documentId:documentId, document:documentToSave, writeOptions: writeOptions, completionHandler: { (document) in
        self.loadUserFiles()
      })
    } else {
      self.appCenter.createDocumentWithPartition(MSDataViewController.DocumentType.User.rawValue.lowercased(), documentId:documentId, document:documentToSave, writeOptions: writeOptions, completionHandler: { (document) in
        self.loadUserFiles()
      })
    }
  }
}
