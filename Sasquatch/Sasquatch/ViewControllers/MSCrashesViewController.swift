import Photos
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
    
    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.tableView.reloadData()
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return categories.count + 2
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let isFirst = section == 0
    let isSecond = section == 1
    if isFirst {
      return 1
    } else if isSecond {
      return 3
    } else {
      return categories[categoryForSection(section - 2)]!.count
    }
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let isFirst = section == 0
    let isSecond = section == 1
    if isFirst {
      return "Breadcrumbs"
    } else if isSecond {
      return "Crashes Settings"
    } else {
      return categoryForSection(section - 2)
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let isFirst = indexPath.section == 0
    let isSecond = indexPath.section == 1
    var cellIdentifier = "crash"
    if isFirst {
      cellIdentifier = "breadcrumbs"
    } else if isSecond {
      if indexPath.row == 0 {
        cellIdentifier = "enable"
      } else {
        cellIdentifier = "attachment"
      }
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
    if isFirst {
      cell.textLabel?.text = "Breadcrumbs"
    } else if isSecond {
      
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
        cell.textLabel?.text = "Text Attachment"
        let text = UserDefaults.standard.string(forKey: "textAttachment") ?? ""
        cell.detailTextLabel?.text = !text.isEmpty ? text : "Empty"
        
        // Binary attachment.
      } else if (indexPath.row == 2) {
        cell.textLabel?.text = "Binary Attachment"
        let referenceUrl = UserDefaults.standard.url(forKey: "fileAttachment")
        cell.detailTextLabel?.text = referenceUrl != nil ? referenceUrl!.absoluteString : "Empty"
        
        // Read async to display size instead of url.
        if referenceUrl != nil {
          let asset = PHAsset.fetchAssets(withALAssetURLs: [referenceUrl!], options: nil).lastObject
          if asset != nil {
            PHImageManager.default().requestImageData(for: asset!, options: nil, resultHandler: {(imageData, dataUTI, orientation, info) -> Void in
              cell.detailTextLabel?.text = ByteCountFormatter.string(fromByteCount: Int64(imageData?.count ?? 0), countStyle: .binary)
            })
          }
        }
      }
    } else {
      let crash = crashByIndexPath(indexPath)
      cell.textLabel?.text = crash.title;
    }
    return cell;
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) -> Void {
    let isFirst = indexPath.section == 0
    let isSecond = indexPath.section == 1
    if isFirst {
      for index in 0...29 {
        let eventName = "Breadcrumb_\(index)"
        appCenter.trackEvent(eventName)
      }
      appCenter.generateTestCrash()
    } else if isSecond {
      
      // Text attachment.
      if indexPath.row == 1 {
        let alert = UIAlertController(title: "Text Attachment", message: nil, preferredStyle: .alert)
        let crashAction = UIAlertAction(title: "OK", style: .default, handler: {(_ action: UIAlertAction) -> Void in
          let result = alert.textFields?[0].text ?? ""
          if !result.isEmpty {
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
        PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in ()
          if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
            let picker = UIImagePickerController()
            picker.delegate = self
            self.present(picker, animated: true)
          }
        })
      }
    } else {
      
      // Crash cell.
      let crash = crashByIndexPath(indexPath)
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
    }
  }
  
  @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    let referenceUrl = info[UIImagePickerControllerReferenceURL] as? URL
    if referenceUrl != nil {
      UserDefaults.standard.set(referenceUrl, forKey: "fileAttachment")
      tableView.reloadData()
    }
    picker.dismiss(animated: true, completion: nil)
  }
  
  @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    UserDefaults.standard.removeObject(forKey: "fileAttachment")
    tableView.reloadData()
    picker.dismiss(animated: true, completion: nil)
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
      if class_getSuperclass(className) == MSCrash.self && className != MSCrash.self {
        MSCrash.register((className as! MSCrash.Type).init())
      }
    }
  }
  
  private func categoryForSection(_ section: Int) -> String {
    return categories.keys.sorted()[section]
  }
  
  private func crashByIndexPath(_ indexPath: IndexPath) -> MSCrash {
    return categories[categoryForSection(indexPath.section - 2)]![indexPath.row]
  }
}

