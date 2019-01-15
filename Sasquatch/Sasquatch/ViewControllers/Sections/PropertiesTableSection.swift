import UIKit

class PropertiesTableSection : NSObject {

  var tableSection: Int
  var tableView: UITableView

  var numberOfCustomHeaderCells: Int {
    get { return 0 }
  }

  var hasInsertRow: Bool {
    get { return true }
  }

  var propertyCellOffset: Int {
    get { return self.numberOfCustomHeaderCells + (self.hasInsertRow ? 1 : 0) }
  }

  init(tableSection: Int, tableView: UITableView) {
    self.tableSection = tableSection
    self.tableView = tableView
    super.init()
  }

  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if isInsertRow(indexPath) {
      return .insert
    } else if isPropertyRow(indexPath) {
      return .delete
    }
    return .none
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return getPropertyCount() + self.propertyCellOffset
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if isInsertRow(indexPath) {
      let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
      cell.textLabel?.text = "Add Property"
      return cell
    }

    return loadCell(row: indexPath.row)
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      removeProperty(atRow: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .automatic)
    } else if editingStyle == .insert {
      addProperty()
      tableView.insertRows(at: [IndexPath(row: indexPath.row + 1, section: indexPath.section)], with: .automatic)
    }
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return isPropertyRow(indexPath) || isInsertRow(indexPath)
  }

  func isInsertRow(_ indexPath: IndexPath) -> Bool {
    return self.hasInsertRow && indexPath.row == self.numberOfCustomHeaderCells
  }

  func isPropertyRow(_ indexPath: IndexPath) -> Bool {
    return indexPath.row >= self.propertyCellOffset
  }

  func loadCell(row: Int) -> UITableViewCell {
    preconditionFailure("This method is abstract")
  }

  func addProperty() {
    preconditionFailure("This method is abstract")
  }

  func removeProperty(atRow row: Int) {
    preconditionFailure("This method is abstract")
  }

  func getPropertyCount() -> Int {
    preconditionFailure("This method is abstract")
  }

  func loadCellFromNib<T: UITableViewCell>() -> T? {
    return Bundle.main.loadNibNamed(String(describing: T.self), owner: self, options: nil)?.first as? T
  }
  
  func reloadSection() {
    tableView.reloadSections([tableSection], with: .none)
  }
}
