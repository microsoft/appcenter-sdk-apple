// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation
import UIKit

class CustomPropertyViewController : UIViewController, UITableViewDataSource, AppCenterProtocol {

  @IBOutlet weak var keyTextField : UITextField?;
  @IBOutlet weak var valueTextField : UITextField?;
  @IBOutlet weak var table : UITableView?;

  var appCenter: AppCenterDelegate!;

  var oldKey : String = "";
  var oldValue : String = "";
  var properties : [String : String] = [String : String]();

  override func viewDidLoad() {
    super.viewDidLoad();
    table?.dataSource = self;
    table?.allowsSelection = true;
    keyTextField?.text = oldKey;
    valueTextField?.text = oldValue;
  }
  
  @IBAction func addProperty(_ sender: Any) {
    let propKey : String = String(format : "key%d", properties.count + 1);
    let propValue : String = String(format : "value%d", properties.count + 1);
    properties.updateValue(propValue, forKey: propKey);
    table?.reloadData();
  }
  
  @IBAction func deleteProperty(_ sender: Any) {
    properties.removeAll();
    table?.reloadData();
  }
  
  //MARK: Table view data source

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return properties.count;
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell : MSPropertyViewCell = tableView.dequeueReusableCell(withIdentifier: "propertyViewCell", for: indexPath) as? MSPropertyViewCell else {
      return UITableViewCell();
    }
    let propKey : String = Array(properties.keys)[indexPath.row];
    cell.propertyKey?.text = propKey;
    cell.propertyValue?.text = properties[propKey];
    return cell;
  }
  
  override func prepare(for seque: UIStoryboardSegue, sender: Any?) {
    guard let editPropertyViewController = seque.destination as? EditPropertyViewController else {
      return;
    }
    
    guard let indexPath = table?.indexPathForSelectedRow else {
      return;
    }
    
    let key : String = Array(properties.keys)[indexPath.row];
    let value : String = properties[key] ?? "";
    
    editPropertyViewController.oldKey = key;
    editPropertyViewController.oldValue = value;
    editPropertyViewController.properties = properties;
    editPropertyViewController.appCenter = appCenter;
  }
}
