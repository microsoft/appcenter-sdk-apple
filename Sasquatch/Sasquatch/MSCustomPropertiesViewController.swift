import UIKit
import MobileCenter

class MSCustomPropertiesViewController : UITableViewController, MobileCenterProtocol {
  var mobileCenter: MobileCenterDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let customProperties = MSCustomProperties()
    
    switch indexPath.section {
    case 0:
      
      switch indexPath.row {
        
      // Set String
      case 0:
        customProperties.setString("test", forKey: "test")
        mobileCenter.setCustomProperties(customProperties)
        break
        
      // Set Number
      case 1:
        customProperties.setNumber(42, forKey: "test")
        mobileCenter.setCustomProperties(customProperties)
        break
        
      // Set Boolean
      case 2:
        customProperties.setBool(false, forKey: "test")
        mobileCenter.setCustomProperties(customProperties)
        break
        
      // Set Date
      case 3:
        customProperties.setDate(Date(), forKey: "test")
        mobileCenter.setCustomProperties(customProperties)
        break
        
      // Set Mutliple
      case 4:
        customProperties.setString("test", forKey: "t1")
        customProperties.setDate(Date(), forKey: "t2")
        customProperties.setNumber(42, forKey: "t3")
        customProperties.setBool(false, forKey: "t4")
        mobileCenter.setCustomProperties(customProperties)
        break
        
      // Clear
      case 5:
        customProperties.clearProperty(forKey: "test")
        mobileCenter.setCustomProperties(customProperties)
        break
        
      default: break
      }
      
    default: break
    }
  }
  
}
