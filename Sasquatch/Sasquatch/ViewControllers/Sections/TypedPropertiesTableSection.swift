import UIKit

class TypedPropertiesTableSection : PropertiesTableSection {

  override func loadCell(row: Int) -> UITableViewCell {
    guard let cell: MSAnalyticsTypedPropertyTableViewCell = loadCellFromNib() else {
      preconditionFailure("Cannot load table view cell")
    }

    return cell
  }
}
