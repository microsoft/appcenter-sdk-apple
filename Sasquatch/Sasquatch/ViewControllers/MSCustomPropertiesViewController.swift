import UIKit

private let kPropertiesSection: Int = 0
private let kEstimatedRowHeight: CGFloat = 88.0

class MSCustomPropertiesViewController : UITableViewController, AppCenterProtocol {
  typealias CustomPropertyType = MSCustomPropertyTableViewCell.CustomPropertyType

  var appCenter: AppCenterDelegate!

  private var properties = [(key: String, type: CustomPropertyType, value: Any?)]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = kEstimatedRowHeight
    tableView.setEditing(true, animated: false)
    
    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
  }
  
  @IBAction func send() {
    let customProperties = MSCustomProperties()
    for property in properties {
      switch property.type {
      case .Clear:
        customProperties.clearProperty(forKey: property.key)
      case .String:
        customProperties.setString(property.value as? String, forKey: property.key)
      case .Number:
        customProperties.setNumber(property.value as? NSNumber, forKey: property.key)
      case .Boolean:
        customProperties.setBool(property.value as! Bool, forKey: property.key)
      case .DateTime:
        customProperties.setDate(property.value as? Date, forKey: property.key)
      }
    }
    appCenter.setCustomProperties(customProperties)
    
    // Clear the list.
    properties.removeAll()
    tableView.reloadData()
    
    // Display a dialog.
    let alertController = UIAlertController(title: "The custom properties log is queued",
                                            message: nil,
                                            preferredStyle:.alert)
    alertController.addAction(UIAlertAction(title: "OK", style: .default))
    present(alertController, animated: true)
  }
  
  @IBAction func onDismissButtonPress(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  func cellIdentifierForRow(at indexPath: IndexPath) -> String {
    var cellIdentifier: String? = nil
    if isSendRow(at: indexPath) {
      cellIdentifier = "send"
    } else if isInsertRow(at: indexPath) {
      cellIdentifier = "insert"
    } else if isDismissRow(at:indexPath) {
      cellIdentifier = "dismiss"
    } else {
      cellIdentifier = "customProperty"
    }
    return cellIdentifier ?? ""
  }
  
  func isInsertRow(at indexPath: IndexPath) -> Bool {
    return isPropertiesRowSection(indexPath.section) && indexPath.row == 0
  }

  func isSendRow(at indexPath: IndexPath) -> Bool {
    return !isPropertiesRowSection(indexPath.section) && indexPath.row == 0
  }

  func isDismissRow(at indexPath: IndexPath) -> Bool {
    return !isPropertiesRowSection(indexPath.section) && indexPath.row == 1
  }

  func isPropertiesRowSection(_ section: Int) -> Bool {
    return section == kPropertiesSection
  }
  
  // MARK: - Table view delegate
  
  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if isInsertRow(at: indexPath) {
      return .insert
    } else {
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
      return properties.count + 1
    } else {
      return 2
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
      properties.remove(at: indexPath.row - 1)
      tableView.deleteRows(at: [indexPath], with: .automatic)
    } else if editingStyle == .insert {
      let count = properties.count
      properties.insert(("key\(count)", CustomPropertyType.String, "value\(count)"), at: 0)
      tableView.insertRows(at: [IndexPath(row: indexPath.row + 1, section: indexPath.section)], with: .automatic)
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cellIdentifier = cellIdentifierForRow(at: indexPath)
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ??
      UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
    if let customPropertyCell = cell as? MSCustomPropertyTableViewCell {
      customPropertyCell.state = properties[indexPath.row - 1]
      customPropertyCell.onChange = { state in
        self.properties[indexPath.row - 1] = state
      }
    }
    return cell
  }
}
