import Foundation

class EditPropertyViewController : UIViewController, MobileCenterProtocol {

  @IBOutlet weak var keyTextField : UITextField?;
  @IBOutlet weak var valueTextField : UITextField?;

  var mobileCenter : MobileCenterDelegate!;

  var oldKey : String = "";
  var oldValue : String = "";
  var properties : [String : String]!;

  override func viewDidLoad() {
    super.viewDidLoad();
    keyTextField?.text = oldKey;
    valueTextField?.text = oldValue;
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    properties.removeValue(forKey: oldKey);
    guard let key = keyTextField?.text, let value = valueTextField?.text else {
      return;
    }
    properties.updateValue(value, forKey: key);
    
    if let destination = segue.destination as? AnalyticsViewController {
      destination.mobileCenter = mobileCenter;
      destination.properties = properties;
    }
  }
}
