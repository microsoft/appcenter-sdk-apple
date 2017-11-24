import UIKit

class MSCrashesViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AppCenterProtocol {
  
  var categories = [String: [MSCrash]]()
  var appCenter: AppCenterDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    pokeAllCrashes()
    
    var crashes = MSCrash.allCrashes() as! [MSCrash]
    crashes = crashes.sorted { (crash1, crash2) -> Bool in
      if crash1.category == crash2.category {
        return crash1.title > crash2.title
      } else {
        return crash1.category > crash2.category
      }
    }
    
    for crash in crashes {
      if categories[crash.category] == nil {
        categories[crash.category] = [MSCrash]()
      }
      categories[crash.category]!.append(crash)
    }
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return categories.count + 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let isLast = section == tableView.numberOfSections - 1
    if isLast {
      return 3
    } else {
      return categories[categoryForSection(section)]!.count
    }
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let isLast = section == tableView.numberOfSections - 1
    if isLast {
      return "Settings"
    } else {
      return categoryForSection(section)
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let isLast = indexPath.section == tableView.numberOfSections - 1
    var cellIdentifier = "crash"
    if isLast {
      if indexPath.row == 0 {
        cellIdentifier = "enable";
      } else {
        cellIdentifier = "attachment";
      }
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
    if isLast {
      
      // Enable.
      if (indexPath.row == 0) {
        
        // Find switch in subviews.
        for view in cell.contentView.subviews {
          if let switchView = view as? UISwitch {
            switchView.isOn = appCenter.isCrashesEnabled()
          }
        }
        
        // Text attachment.
      } else if (indexPath.row == 1) {
        cell.textLabel?.text = "Text attachment";
        let text = UserDefaults.standard.string(forKey: "textAttachment")
        cell.detailTextLabel?.text = text != nil && text!.count > 0 ? text : "Empty";
        
        // Binary attachment.
      } else if (indexPath.row == 2) {
        cell.textLabel?.text = "Binary attachment";
        let referenceUrl = UserDefaults.standard.url(forKey: "fileAttachment")
        cell.detailTextLabel?.text = referenceUrl != nil ? referenceUrl!.absoluteString : "Empty";
        
      }
    } else {
      let crash = categories[categoryForSection(indexPath.section)]![indexPath.row]
      cell.textLabel?.text = crash.title;
    }
    return cell;
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) -> Void {
    let isLast = indexPath.section == tableView.numberOfSections - 1
    if !isLast {
      
      // Crash cell.
      let crash = categories[categoryForSection(indexPath.section)]![indexPath.row]
      let alert = UIAlertController(title: crash.title, message: crash.desc, preferredStyle: .actionSheet)
      let crashAction = UIAlertAction(title: "Crash", style: .destructive, handler: {(_ action: UIAlertAction) -> Void in
        crash.crash()
      })
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(_ action: UIAlertAction) -> Void in
        alert.dismiss(animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
      })
      alert.addAction(crashAction)
      alert.addAction(cancelAction)
      
      // Support display in iPad.
      alert.popoverPresentationController?.sourceView = tableView
      alert.popoverPresentationController?.sourceRect = tableView.rectForRow(at: indexPath)
      
      present(alert, animated: true)
    } else {
      
      // Text attachment.
      if indexPath.row == 1 {
        let alert = UIAlertController(title: "Text attachment", message: nil, preferredStyle: .alert)
        let crashAction = UIAlertAction(title: "OK", style: .default, handler: {(_ action: UIAlertAction) -> Void in
          let result: String? = alert.textFields?[0].text
          if result != nil && result!.count > 0 {
            UserDefaults.standard.set(result, forKey: "textAttachment")
          } else {
            UserDefaults.standard.removeObject(forKey: "textAttachment")
          }
          tableView.reloadData()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(crashAction)
        alert.addAction(cancelAction)
        alert.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
          textField.text = UserDefaults.standard.string(forKey: "textAttachment")
        })
        present(alert, animated: true)
        
        // Binary attachment.
      } else if indexPath.row == 2 {
        let picker = UIImagePickerController()
        picker.delegate = self
        present(picker, animated: true)
      }
    }
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    picker.dismiss(animated: true)
    let referenceUrl = info[UIImagePickerControllerReferenceURL] as? URL
    if referenceUrl != nil {
      UserDefaults.standard.set(referenceUrl, forKey: "fileAttachment")
    }
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    UserDefaults.standard.removeObject(forKey: "fileAttachment")
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setCrashesEnabled(sender.isOn)
    sender.isOn = appCenter.isCrashesEnabled()
  }
  
  private func pokeAllCrashes() {
    var count = UInt32(0)
    let classList = objc_copyClassList(&count)
    MSCrash.removeAllCrashes()
    for i in 0..<Int(count){
      let className: AnyClass = classList![i]!
      if class_getSuperclass(className) == MSCrash.self && className != MSCrash.self{
        MSCrash.register((className as! MSCrash.Type).init())
      }
    }
  }
  
  private func categoryForSection(_ section: Int) -> String{
    return categories.keys.sorted()[section]
  }
}

