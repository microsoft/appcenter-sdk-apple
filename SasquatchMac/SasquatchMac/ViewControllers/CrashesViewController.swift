import Cocoa

class CrashesViewController : NSViewController, NSTableViewDataSource, NSTableViewDelegate {

  var mobileCenter: MobileCenterDelegate = MobileCenterProvider.shared().mobileCenter!
  var crashes = [Any]()
  @IBOutlet var setEnabledButton : NSButton?
  @IBOutlet weak var crashesTableView: NSTableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    loadAllCrashes()
    crashesTableView.dataSource = self
    crashesTableView.delegate = self
    setEnabledButton?.state = mobileCenter.isCrashesEnabled() ? 1 : 0
  }

  @IBAction func setEnabled(sender : NSButton) {
    mobileCenter.setCrashesEnabled(sender.state == 1)
    sender.state = mobileCenter.isCrashesEnabled() ? 1 : 0
  }

  func numberOfRows(in tableView: NSTableView) -> Int {
    return crashes.count;
  }

  func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
    return isHeader(row: row)
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    if isHeader(row: row) {
      let categoryView = tableView.make(withIdentifier: "crashName", owner: nil) as! NSTextField
      categoryView.stringValue = crashes[row] as! String
      categoryView.alignment = NSTextAlignment.center
      categoryView.font = NSFontManager.shared().convert(categoryView.font!, toHaveTrait: NSFontTraitMask(rawValue: UInt(NSFontBoldTrait)))
      return categoryView
    } else {
      switch tableColumn {
      case tableView.tableColumns[0]?:
        let nameView = tableView.make(withIdentifier: "crashName", owner: nil) as! NSTextField
        nameView.stringValue = (crashes[row] as! MSCrash).title
        return nameView
      case tableView.tableColumns[1]?:
        let crashButton = tableView.make(withIdentifier: "crashButton", owner: nil) as! NSButton
        crashButton.tag = row
        crashButton.target = self
        crashButton.action = #selector(CrashesViewController.crashButtonPressed)
        return crashButton
      default: break
      }
    }
    return nil
  }

  func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    return 30
  }

  func crashButtonPressed(_ sender: Any) {
    (crashes[(sender as! NSButton).tag] as! MSCrash).crash()
  }

  private func isHeader(row: Int) -> Bool {
    return crashes[row] is String
  }

  private func loadAllCrashes() {
    pokeAllCrashes()
    var sortedCrashes = MSCrash.allCrashes() as! [MSCrash]
    sortedCrashes = sortedCrashes.sorted { (crash1, crash2) -> Bool in
      if crash1.category == crash2.category{
        return crash1.title > crash2.title
      } else {
        return crash1.category < crash2.category
      }
    }
    if sortedCrashes.count > 0 {
      var currentCategory = sortedCrashes[0].category!
      crashes.append(currentCategory as Any)
      for crash in sortedCrashes {
        if currentCategory != crash.category {
          currentCategory = crash.category
          crashes.append(currentCategory as Any)
        }
        crashes.append(crash as Any)
      }
    }
  }

  private func pokeAllCrashes() {
    var count = UInt32(0)
    let classList = objc_copyClassList(&count)
    MSCrash.removeAllCrashes()
    for i in 0..<Int(count){
      let className = classList![i]!
      if class_getSuperclass(className) == MSCrash.self && className != MSCrash.self{
        MSCrash.register((className as! MSCrash.Type).init())
      }
    }
  }
}
