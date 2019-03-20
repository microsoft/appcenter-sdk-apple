// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation
import UIKit

class MSPropertyViewCell : UITableViewCell {

  static let identifier : String = "propertyCell";

  @IBOutlet weak var propertyKey : UITextField?;
  @IBOutlet weak var propertyValue : UITextField?;
}
