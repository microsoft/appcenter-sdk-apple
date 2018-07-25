import UIKit

class CommonSchemaPropertiesTableSection : PropertiesTableSection {
  
  var targets: [String: [(String, String)]]!
  var transmissionTargetSelectorCell: MSAnalyticsTransmissionTargetSelectorViewCell?
  
  enum CommonSchemaProperty : Int {
    case AppName = 1
    case AppVersion
    case AppLocale
  }
  
  var propertyTuples = [("appName", ""), ("appVersion", ""), ("appLocale", "")]
  
  override init(tableSection: Int, tableView: UITableView) {
    super.init(tableSection: tableSection, tableView: tableView)
    targets = [String: [(String, String)]]()
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    let parentTargetToken = appName == "SasquatchSwift" ? kMSSwiftRuntimeTargetToken : kMSObjCRuntimeTargetToken
    targets[parentTargetToken] = [(String, String)](propertyTuples)
    targets[kMSTargetToken1] = [(String, String)](propertyTuples)
    targets[kMSTargetToken2] = [(String, String)](propertyTuples)
    transmissionTargetSelectorCell = loadCellFromNib()
    transmissionTargetSelectorCell?.didSelectTransmissionTarget = reloadSection
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.row == 0 {
      return transmissionTargetSelectorCell!
    } else {
      let cell: MSAnalyticsPropertyTableViewCell? = loadCellFromNib()
      cell?.valueField.placeholder = "Override value"
      
      // Set cell text.
      var label : String = ""
      switch indexPath.row {
      case CommonSchemaProperty.AppName.rawValue:
        label = "App Name"
        break
        
      case CommonSchemaProperty.AppVersion.rawValue:
        label = "App Version"
        break
        
      case CommonSchemaProperty.AppLocale.rawValue:
        label = "App Locale"
        break
      default:
        break
      }
      cell!.keyField.text = label
      
      let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()

      cell!.valueField.text = targets[selectedTarget!]![indexPath.row - 1].1
      
      // Set cell to respond to being edited.
      cell!.valueField.addTarget(self, action: #selector(propertyValueChanged), for: .editingChanged)
      cell!.valueField.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEndOnExit)
      return cell!
    }
  }
  
  override func propertyValueChanged(sender: UITextField!) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let propertyIndex = getCellRow(forTextField: sender) - propertyCellOffset()
    let tableIndex = propertyIndex + 1;
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    targets[selectedTarget!]![propertyIndex].1 = sender.text!
    
    if sender.text == nil  || sender.text!.isEmpty {
      return;
    }
    
    switch tableIndex {
    case CommonSchemaProperty.AppName.rawValue:
      target.propertyConfigurator.setAppName(sender.text!)
      break
    case CommonSchemaProperty.AppVersion.rawValue:
      target.propertyConfigurator.setAppVersion(sender.text!)
      break
    case CommonSchemaProperty.AppLocale.rawValue:
      target.propertyConfigurator.setAppLocale(sender.text!)
      break
    default:
      break
    }
  }
  
  override func getPropertyCount() -> Int {
    return 3
  }
}
