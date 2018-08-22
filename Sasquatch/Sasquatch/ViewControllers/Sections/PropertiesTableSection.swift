import UIKit

class PropertiesTableSection : NSObject, UITableViewDelegate {

  static var propertyCounter = 0
  var tableSection: Int
  var tableView: UITableView

  init(tableSection: Int, tableView: UITableView) {
    self.tableSection = tableSection
    self.tableView = tableView
    super.init()
  }

  @objc(tableView:editingStyleForRowAtIndexPath:) func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if isInsertRow(indexPath) {
      return .insert
    } else if isPropertyRow(indexPath) {
      return .delete
    }
    return .none
  }

  @objc(tableView:numberOfRowsInSection:) func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return getPropertyCount() + propertyCellOffset()
  }

  @objc(tableView:cellForRowAtIndexPath:) func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if isInsertRow(indexPath) {
      let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
      cell.textLabel?.text = "Add Property"
      return cell
    }
    let cell: MSAnalyticsPropertyTableViewCell? = loadCellFromNib()

    // Set cell text.
    let property = propertyAtRow(row: indexPath.row)
    cell!.keyField.text = property.0
    cell!.valueField.text = property.1

    // Set cell to respond to being edited.
    cell!.keyField.addTarget(self, action: #selector(propertyKeyChanged), for: .editingChanged)
    cell!.keyField.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEndOnExit)
    cell!.valueField.addTarget(self, action: #selector(propertyValueChanged), for: .editingChanged)
    cell!.valueField.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEndOnExit)

    return cell!
  }

  @objc(tableView:commitEditingStyle:forRowAtIndexPath:) func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      removeProperty(atRow: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .automatic)
    } else if editingStyle == .insert {
      addProperty(property: PropertiesTableSection.getNewDefaultProperty())
      tableView.insertRows(at: [IndexPath(row: indexPath.row + 1, section: indexPath.section)], with: .automatic)
    }
  }

  @objc(tableView:canEditRowAtIndexPath:) func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return isPropertyRow(indexPath) || isInsertRow(indexPath)
  }

  func numberOfCustomHeaderCells() -> Int {
    return 0
  }

  func isInsertRow(_ indexPath: IndexPath) -> Bool {
    return indexPath.row == numberOfCustomHeaderCells()
  }

  func isPropertyRow(_ indexPath: IndexPath) -> Bool {
    return indexPath.row > numberOfCustomHeaderCells()
  }

  func removeProperty(atRow row: Int) {
    preconditionFailure("This method is abstract")
  }

  func addProperty(property: (String, String)) {
    preconditionFailure("This method is abstract")
  }

  func propertyKeyChanged(sender: UITextField!) {
    preconditionFailure("This method is abstract")
  }

  func propertyValueChanged(sender: UITextField!) {
    preconditionFailure("This method is abstract")
  }
  
  func dismissKeyboard(sender: UITextField!) {
    sender.resignFirstResponder()
  }

  func propertyAtRow(row: Int) -> (String, String) {
    preconditionFailure("This method is abstract")
  }

  func getPropertyCount() -> Int {
    preconditionFailure("This method is abstract")
  }

  func loadCellFromNib<T: UITableViewCell>() -> T? {
    return Bundle.main.loadNibNamed(String(describing: T.self), owner: self, options: nil)?.first as? T
  }

  func propertyCellOffset() -> Int {
    return numberOfCustomHeaderCells() + 1
  }

  func getCellRow(forTextField textField: UITextField) -> Int {
    let cell = textField.superview!.superview as! MSAnalyticsPropertyTableViewCell
    let indexPath = tableView.indexPath(for: cell)!
    return indexPath.row
  }

  static func getNewDefaultProperty() -> (String, String) {
    let keyValuePair = ("key\(propertyCounter)", "value\(propertyCounter)")
    propertyCounter += 1
    return keyValuePair
  }
  
  func reloadSection() {
    tableView.reloadSections([tableSection], with: .none)
  }
}



