// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation
import UIKit

class EditPropertyViewController: UIViewController, AppCenterProtocol {
  
  @IBOutlet weak var keyTextField : UITextField?;
  @IBOutlet weak var valueTextField : UITextField?;
  
  var appCenter: AppCenterDelegate!;
  
  var oldKey : String = "";
  var oldValue : String = "";
  var properties : [String : String]!;

    override func viewDidLoad() {
        super.viewDidLoad()
      keyTextField?.text = oldKey
      valueTextField?.text = oldValue
    }

  override func prepare(for seque: UIStoryboardSegue, sender: Any?) {
    properties.removeValue(forKey: oldKey);
    guard let key = keyTextField?.text, let value = valueTextField?.text else {
      return;
    }
    properties.updateValue(value, forKey: key);
    
    if let destination = seque.destination as? CustomPropertyViewController {
      destination.appCenter = appCenter;
      destination.properties = properties;
    }
  }
}
