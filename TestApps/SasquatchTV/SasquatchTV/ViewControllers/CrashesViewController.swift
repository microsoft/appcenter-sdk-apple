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
    return categories.count + 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let isLast = section == tableView.numberOfSections - 1
    if isLast{
      return 1
    } else {
      return categories[categoryForSection(section)]!.count
    }
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let isLast = section == tableView.numberOfSections - 1
    if isLast{
      return "Settings"
    } else {
      return categoryForSection(section)
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let isLast = indexPath.section == tableView.numberOfSections - 1
    let cellIdentifier = isLast ? "enable" : "crash"
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
    if isLast{
      cell.detailTextLabel?.text = appCenter.isCrashesEnabled() ? "Enabled" : "Disabled";
    } else {
      let crash = categories[categoryForSection(indexPath.section)]![indexPath.row]
      cell.textLabel?.text = crash.title;
    }
    return cell;
  }

  override func tableView(_ tableView : UITableView, didSelectRowAt indexPath : IndexPath) {
    tableView.deselectRow(at : indexPath, animated : true);
    let isLast = indexPath.section == tableView.numberOfSections - 1
    if isLast {
      appCenter.setCrashesEnabled(!appCenter.isCrashesEnabled());
      tableView.reloadData();
    }
  }

  private func pokeAllCrashes(){
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
