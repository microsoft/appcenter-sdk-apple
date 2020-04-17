// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class CrashesViewController: UITableViewController, AppCenterProtocol {

  var categories = [String: [MSCrash]]()
  var appCenter: AppCenterDelegate!

  override func viewDidLoad() {
    super.viewDidLoad()
    pokeAllCrashes()

    var crashes = MSCrash.allCrashes() as! [MSCrash]
    crashes = crashes.sorted { (crash1, crash2) -> Bool in
      if crash1.category == crash2.category{
        return crash1.title > crash2.title
      } else {
        return crash1.category > crash2.category
      }
    }

    for crash in crashes {
      if categories[crash.category] == nil{
        categories[crash.category] = [MSCrash]()
      }
      categories[crash.category]!.append(crash)
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "crash-detail"{
      if let selectedRow = tableView.indexPathForSelectedRow{
        let crash = categories[categoryForSection(selectedRow.section)]![selectedRow.row]
        (segue.destination as! CrashesDetailViewController).crash = crash;
      }
    }
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return categories.count + 2
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let isFirst = section == 0
    let isSecond = section == 1
    if isFirst{
      return 1
    } else if (isSecond) {
      return 1
    } else {
      return categories[categoryForSection(section)]!.count
    }
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let isFirst = section == 0
    let isSecond = section == 1
    if isFirst{
      return "Settings"
    } else if (isSecond) {
      return "Breadcrumbs"
    } else {
      return categoryForSection(section)
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let isFirst = indexPath.section == 0
    let isSecond = indexPath.section == 1
    let cellIdentifier = isFirst ? "enable" : isSecond ? "breadcrumbs" : "crash"
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
    if isFirst{
      cell.detailTextLabel?.text = appCenter.isCrashesEnabled() ? "Enabled" : "Disabled";
    } else if isSecond {
      cell.textLabel?.text = "Breadcrumbs"
    } else {
      let crash = categories[categoryForSection(indexPath.section)]![indexPath.row]
      cell.textLabel?.text = crash.title;
    }
    return cell;
  }

  override func tableView(_ tableView : UITableView, didSelectRowAt indexPath : IndexPath) {
    tableView.deselectRow(at : indexPath, animated : true);
    let isFirst = indexPath.section == 0
    let isSecond = indexPath.section == 1
    if isFirst {
      appCenter.setCrashesEnabled(!appCenter.isCrashesEnabled());
      tableView.reloadData();
    } else if isSecond {
      for index in 1...29 {
        appCenter.trackEvent("Breadcrumb \(index)")
      }
      appCenter.generateTestCrash()
    }
  }

  private func pokeAllCrashes() {
    var count = UInt32(0)
    let classList = objc_copyClassList(&count)
    let classes = UnsafeBufferPointer(start: classList, count: Int(count))
    MSCrash.removeAllCrashes()
    for i in 0..<Int(count){
      let className: AnyClass = classes[i]
      if class_getSuperclass(className) == MSCrash.self && className != MSCrash.self {
        MSCrash.register((className as! MSCrash.Type).init())
      }
    }
  }

  private func categoryForSection(_ section: Int) -> String {
    
    // Skip 2 for Enabled and Breadcumb rows.
    return categories.keys.sorted()[section - 2]
  }
}
