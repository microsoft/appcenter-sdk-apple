import UIKit
import AppCenter

private var kPropertiesSection: Int = 0

class MSCustomPropertiesViewController : UITableViewController, AppCenterProtocol {
  
  var propertiesCount: Int = 0
  var appCenter: AppCenterDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.setEditing(true, animated: false)
  }
  
  @IBAction func send() {
    let customProperties = MSCustomProperties()
    for i in 0..<propertiesCount {
      let cell = tableView.cellForRow(at: IndexPath(row: i, section: kPropertiesSection)) as? MSCustomPropertyTableViewCell
      cell?.setPropertyTo(customProperties)
    }
    appCenter.setCustomProperties(customProperties)
    
    // Clear the list.
    propertiesCount = 0
    tableView.reloadData()
    
    // Display a dialog.
    let alertController = UIAlertController(title: "The custom properties log is queued",
                                            message: nil,
                                            preferredStyle:.alert)
    alertController.addAction(UIAlertAction(title: "OK", style: .default))
    present(alertController, animated: true)
  }
  
  func cellIdentifierForRow(at indexPath: IndexPath) -> String {
    var cellIdentifier: String? = nil
    if !isPropertiesRowSection(indexPath.section) {
      cellIdentifier = "send"
    } else if isInsertRow(at: indexPath) {
      cellIdentifier = "insert"
    } else {
      cellIdentifier = "customProperty"
    }
    return cellIdentifier ?? ""
  }
  
  func isInsertRow(at indexPath: IndexPath) -> Bool {
    return indexPath.section == kPropertiesSection && indexPath.row == tableView(tableView, numberOfRowsInSection: indexPath.section) - 1
  }
  
  func isPropertiesRowSection(_ section: Int) -> Bool {
    return section == kPropertiesSection
  }
  
  // MARK: - Table view delegate
  
  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if isInsertRow(at: indexPath) {
      return .insert
    }
    else {
      return .delete
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if isInsertRow(at: indexPath) {
      self.tableView(tableView, commit: .insert, forRowAt: indexPath)
    }
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if isPropertiesRowSection(section) {
      return propertiesCount + 1
    } else {
      return 1
    }
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if isPropertiesRowSection(section) {
      return "Properties"
    }
    return nil
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return isPropertiesRowSection(indexPath.section)
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      propertiesCount -= 1
      tableView.deleteRows(at: [indexPath], with: .automatic)
    } else if editingStyle == .insert {
      propertiesCount += 1
      tableView.insertRows(at: [indexPath], with: .automatic)
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cellIdentifier = cellIdentifierForRow(at: indexPath)
    var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
    if cell == nil {
      cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
    }
    return cell!
  }
}
