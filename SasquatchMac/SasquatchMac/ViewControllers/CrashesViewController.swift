// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Cocoa

class CrashesViewController : NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextViewDelegate {

  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!
  var crashes = [Any]()
  @IBOutlet var setEnabledButton : NSButton?
  @IBOutlet weak var crashesTableView: NSTableView!
  @IBOutlet weak var fileAttachmentLabel: NSTextField!
  @IBOutlet var textAttachmentView: NSTextView!
  @IBOutlet weak var breadCrumbsButton : NSButton?
  @IBOutlet var clearCrashUserConfirmationButton: NSButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    crashes = CrashLoader.loadAllCrashes()
    crashesTableView.dataSource = self
    crashesTableView.delegate = self
    textAttachmentView.delegate = self
    
    let text = UserDefaults.standard.string(forKey: "textAttachment") ?? ""
    if !text.isEmpty {
      textAttachmentView.string = text;
    }
    let referenceUrl = UserDefaults.standard.url(forKey: "fileAttachment")
    if referenceUrl != nil {
      fileAttachmentLabel.stringValue = self.fileAttachmentDescription(url: referenceUrl)
    }
  }

  override func viewWillAppear() {
    setEnabledButton?.state = appCenter.isCrashesEnabled() ? .on : .off
  }
  
  @IBAction func generateBreadCrumbsAndCrash(sender: NSButton) {
    for index in 0...29 {
      appCenter.trackEvent("Breadcrumb \(index)")
    }
    appCenter.generateTestCrash()
  }

  @IBAction func setEnabled(sender : NSButton) {
    appCenter.setCrashesEnabled(sender.state == .on)
    sender.state = appCenter.isCrashesEnabled() ? .on : .off
  }

  @IBAction func clearCrashUserConfirmation(_ sender: Any) {
    let alert: NSAlert = NSAlert()
    alert.messageText = "Clear crash user confirmation?"
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")
    alert.alertStyle = .warning
    switch(alert.runModal()) {
    case .alertFirstButtonReturn:
        UserDefaults.standard.removeObject(forKey: kMSUserConfirmationKey)
        break
    default:
        break
    }
  }
  
  @IBAction func browseFileAttachment(_ sender: Any) {
    let openPanel = NSOpenPanel()
    openPanel.begin(completionHandler: { (result) -> Void in
      let url = result.rawValue == NSFileHandlingPanelOKButton && openPanel.url != nil ? openPanel.url : nil
      if url != nil {
        UserDefaults.standard.set(url, forKey: "fileAttachment")
      } else {
        UserDefaults.standard.removeObject(forKey: "fileAttachment")
      }
      self.fileAttachmentLabel.stringValue = self.fileAttachmentDescription(url: url)
    })
  }

  func textDidChange(_ notification: Notification) {
    let text = textAttachmentView.string ?? ""
    if !text.isEmpty {
      UserDefaults.standard.set(text, forKey: "textAttachment")
    } else {
      UserDefaults.standard.removeObject(forKey: "textAttachment")
    }
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return crashes.count;
  }

  func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
    return isHeader(row: row)
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    if isHeader(row: row) {
      let categoryView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "crashName"), owner: nil) as! NSTextField
      categoryView.stringValue = crashes[row] as! String
      categoryView.alignment = NSTextAlignment.center
      categoryView.font = NSFontManager.shared.convert(categoryView.font!, toHaveTrait: NSFontTraitMask(rawValue: UInt(NSFontBoldTrait)))
      return categoryView
    } else {
      switch tableColumn {
      case tableView.tableColumns[0]?:
        let nameView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "crashName"), owner: nil) as! NSTextField
        nameView.stringValue = (crashes[row] as! MSCrash).title
        return nameView
      case tableView.tableColumns[1]?:
        let crashButton = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "crashButton"), owner: nil) as! NSButton
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

  @objc func crashButtonPressed(_ sender: Any) {
    (crashes[(sender as! NSButton).tag] as! MSCrash).crash()
  }
  
  private func isHeader(row: Int) -> Bool {
    return crashes[row] is String
  }
  
  private func fileAttachmentDescription(url: URL?) -> String {
    if url != nil {
      var desc = "File: \(url!.lastPathComponent)"
      do {
        let attr = try FileManager.default.attributesOfItem(atPath: url!.path)
        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(attr[FileAttributeKey.size] as! UInt64), countStyle: .binary)
        desc += " Size: \(fileSize)"
      } catch {
        print(error)
      }
      return desc
    } else {
      return "Empty"
    }
  }
}
