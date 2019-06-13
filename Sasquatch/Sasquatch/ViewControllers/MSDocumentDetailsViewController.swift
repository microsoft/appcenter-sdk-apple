// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSDocumentDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AppCenterProtocol {
  var documentType: String?
  var appCenter: AppCenterDelegate!
  
  enum TimeToLiveMode: String {
    case Default = "Default"
    case NoCache = "NoCache"
    case TwoSeconds = "2 seconds"
    case Infinite = "Infinite"
    static let allValues = [Default, NoCache, TwoSeconds, Infinite]
  }
  @IBOutlet weak var saveBtn: UIButton!
  var replaceDocument: Bool = false
  var document: MSDictionaryDocument?
  var writeOptions: MSWriteOptions?
  var documentId: String?
  var documentTimeToLive: String? = TimeToLiveMode.Default.rawValue
  var userDocumentAddPropertiesSection: EventPropertiesTableSection!
  let userType: String = MSDataViewController.DocumentType.User.rawValue
  var documentContent: MSDocumentWrapper?
  private var kUserDocumentAddPropertiesSectionIndex: Int = 0
  private var timeToLiveModePicker: MSEnumPicker<TimeToLiveMode>?
  
  @IBOutlet weak var timeToLiveBoard: UILabel!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var refreshButton: UIButton!
  @IBOutlet weak var docIdField: UITextField!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var timeToLiveField: UITextField!

  override func viewDidLoad() {
    super.viewDidLoad()
    docIdField.placeholder = "Please input a user document id"
    docIdField.text = documentId
    timeToLiveField.text = documentTimeToLive
    self.tableView.delegate = self
    self.tableView.dataSource = self
    self.tableView.setEditing(true, animated: false)
  }

  override func loadView() {
    super.loadView()
    if documentContent == nil || documentId == nil {
      docIdField.isEnabled = true
    }
    if documentType != userType {
      timeToLiveField.isHidden = true
      timeToLiveBoard.isHidden = true
      saveBtn.isHidden = true
    }
    userDocumentAddPropertiesSection = EventPropertiesTableSection(tableSection: 0, tableView: self.tableView)
    self.timeToLiveModePicker = MSEnumPicker<TimeToLiveMode> (
      textField: self.timeToLiveField,
      allValues: TimeToLiveMode.allValues,
      onChange: { index in
        self.documentTimeToLive = TimeToLiveMode.allValues[index].rawValue
      }
    )
    self.timeToLiveField.delegate = self.timeToLiveModePicker
    self.timeToLiveField.text = self.timeToLiveField.text
    self.timeToLiveField.tintColor = UIColor.clear
  }
  
  func shouldDisplayProperties(in section: Int) -> Bool {
    return documentType == userType && section == kUserDocumentAddPropertiesSectionIndex
  }

  @IBAction func backButtonClicked(_ sender: Any) {
    self.presentingViewController?.dismiss(animated: true, completion: nil)
  }

  @IBAction func refreshButtonClicked(_ sender: Any) {
    var partition = documentContent?.partition ?? ""
    if (partition.contains("user")) {
        partition = "user"
    }
    self.appCenter.readDocumentWithPartition(partition, documentId: documentContent?.documentId ?? "", documentType: MSDictionaryDocument.self, completionHandler: { (document) in
        self.documentContent = document
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        if (partition == "user") {
            let index = MSDataViewController.UserDocuments.firstIndex(where: {$0.documentId == self.documentId} )
            if (index != nil) {
                MSDataViewController.UserDocuments[index!] = self.documentContent ?? MSDataViewController.UserDocuments[index!]
            }
        } else {
            let index = MSDataViewController.AppDocuments.firstIndex(where: {$0.documentId == self.documentId} )
            if (index != nil) {
                MSDataViewController.AppDocuments[index!] = self.documentContent ?? MSDataViewController.AppDocuments[index!]
            }
        }
    })
  }
    
  func numberOfSections(in tableView: UITableView) -> Int {
    if documentType != userType {
      return 1
    } else if (documentId != nil && documentId!.isEmpty) {
      return 2
    }
    return 3
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if shouldDisplayProperties(in: section) {
      return userDocumentAddPropertiesSection.tableView(tableView, numberOfRowsInSection: section)
    } else if documentContent == nil {
      return 1
    } else if documentType == userType && section == 1 {
      return 0
    }
    return 4
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if shouldDisplayProperties(in: indexPath.section) {
      return userDocumentAddPropertiesSection.tableView(tableView, canEditRowAt:indexPath)
    } else if documentType == userType && (documentContent == nil){
      return true
    }
    return false
  }

  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    if shouldDisplayProperties(in: indexPath.section) {
      return userDocumentAddPropertiesSection.tableView(tableView, editingStyleForRowAt: indexPath)
    }
    return .none
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if shouldDisplayProperties(in: indexPath.section) {
      userDocumentAddPropertiesSection.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
    }
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if shouldDisplayProperties(in: indexPath.section) && userDocumentAddPropertiesSection.isInsertRow(indexPath) {
      self.tableView(tableView, commit: .insert, forRowAt: indexPath)
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if shouldDisplayProperties(in: indexPath.section) {
      return userDocumentAddPropertiesSection.tableView(tableView, cellForRowAt:indexPath)
    } else if documentContent != nil {
      let cell = tableView.dequeueReusableCell(withIdentifier: "property", for: indexPath)
      var cellText = ""
      switch indexPath.row {
        case 0:
          cellText = "Document ID: \(documentContent?.documentId ?? "")"
        break
        case 1:
          cellText = "Partition: \(documentContent?.partition ?? "")"
        break
        case 2:
          if documentContent != nil && documentContent?.lastUpdatedDate != nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy HH:mm"
            cellText = "Last update date: \(formatter.string(from: documentContent?.lastUpdatedDate ?? Date()))"
          } else {
            cellText = "Last update date: unknown"
          }
          break
        
        case 3:
          guard (documentContent?.error) != nil else {
            cell.textLabel?.numberOfLines = 0;
            cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping;
            let dictionary = documentContent?.deserializedValue.serializeToDictionary() ?? [:]
            do {
              let jsonData = try String(data: JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted), encoding: String.Encoding.utf8)
              cellText = "Document content: \(jsonData ?? "unknown")"
            } catch {
              cellText = "Document content could not be deserialized."
            }
            break
          }
        break
      default:
        cellText = "nil"
      }
      cell.textLabel?.text = cellText
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: "property", for: indexPath)
      return cell
    }
  }
  
  func convertTimeToLiveConstantToValue(_ constValue : String) -> Int {
    switch constValue {
      case TimeToLiveMode.Infinite.rawValue:
      return -1
      case TimeToLiveMode.NoCache.rawValue:
      return 0
      case TimeToLiveMode.TwoSeconds.rawValue:
      return 2
    default:
      return 60 * 60 * 24
    }
  }
  
  func prepareToSaveFile() {
    if (documentContent != nil) {
      replaceDocument = true
    }
    var prop = [AnyHashable: Any]()
    if !((docIdField.text?.isEmpty)!) {
      documentId = docIdField.text
      let docProperties = userDocumentAddPropertiesSection.typedProperties
      for property in docProperties {
        switch property.type {
        case .String:
          prop[property.key] = property.value as! String
        case .Double:
          prop[property.key] = property.value as! Double
        case .Long:
          prop[property.key] = property.value as! Int64
        case .Boolean:
          prop[property.key] = property.value as! Bool
        case .DateTime:
          prop[property.key] = property.value as! Date
        }
      }
    }
    self.document = MSDictionaryDocument.init(from: prop)
    self.writeOptions = MSWriteOptions.init(deviceTimeToLive:self.convertTimeToLiveConstantToValue(self.documentTimeToLive!))
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?)  {
    if segue.identifier == "SaveDocument" {
      prepareToSaveFile()
    }
  }
}
