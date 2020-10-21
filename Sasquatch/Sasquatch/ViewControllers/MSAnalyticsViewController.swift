// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSAnalyticsViewController: UITableViewController, AppCenterProtocol {
  
  enum Priority: String {
    case Default = "Default"
    case Normal = "Normal"
    case Critical = "Critical"
    case Invalid = "Invalid"

    var flags: Flags {
      switch self {
      case .Normal:
        return [.normal]
      case .Critical:
        return [.critical]
      case .Invalid:
        return Flags.init(rawValue: 42)
      default:
        return []
      }
    }

    static let allValues = [Default, Normal, Critical, Invalid]
  }
  
  enum Latency: String {
    case Default = "Default"
    case Min_10 = "10 Minutes"
    case Hour_1 = "1 Hour"
    case Hour_8 = "8 Hour"
    case Day_1 = "1 Day"
    
    static let allValues = [Default, Min_10, Hour_1, Hour_8, Day_1]
    static let allTimeValues = [3, 10*60, 1*60*60, 8*60*60, 24*60*60]
  }

  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var eventName: UITextField!
  @IBOutlet weak var pageName: UITextField!
  @IBOutlet weak var pause: UIButton!
  @IBOutlet weak var resume: UIButton!
  @IBOutlet weak var priorityField: UITextField!
  @IBOutlet weak var countLabel: UILabel!
  @IBOutlet weak var countSlider: UISlider!
  @IBOutlet weak var transmissionIntervalLabel: UILabel!
  
  var appCenter: AppCenterDelegate!
  var eventPropertiesSection: EventPropertiesTableSection!
  @objc(analyticsResult) var analyticsResult: MSAnalyticsResult? = nil
  private var latencyPicker: MSEnumPicker<Latency>?
  private var priorityPicker: MSEnumPicker<Priority>?
  private var priority = Priority.Default
  private var latency = Latency.Default
  private var kEventPropertiesSectionIndex: Int = 2
  private var kResultsPageIndex: Int = 2

  override func viewDidLoad() {
    eventPropertiesSection = EventPropertiesTableSection(tableSection: kEventPropertiesSectionIndex, tableView: tableView)
    super.viewDidLoad()
    tableView.estimatedRowHeight = tableView.rowHeight
    tableView.rowHeight = UITableView.automaticDimension
    tableView.setEditing(true, animated: false)

    self.priorityPicker = MSEnumPicker<Priority>(
      textField: self.priorityField,
      allValues: Priority.allValues,
      onChange: {(index) in self.priority = Priority.allValues[index] })
    self.priorityField.delegate = self.priorityPicker
    self.priorityField.text = self.priority.rawValue
    self.priorityField.tintColor = UIColor.clear
    self.countLabel.text = "Count: \(Int(countSlider.value))"
    
    initTransmissionIntervalLabel()
    
    // Disable results page.
    #if !ACTIVE_COMPILATION_CONDITION_PUPPET
    let cell = tableView.cellForRow(at: IndexPath(row: kResultsPageIndex, section: 0))
    cell?.isUserInteractionEnabled = false
    cell?.contentView.alpha = 0.5
    #endif
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.enabled.isOn = appCenter.isAnalyticsEnabled()
    
    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
  }

  @IBAction func trackEvent() {
    guard let name = eventName.text else {
      return
    }
    let eventProperties = eventPropertiesSection.eventProperties()
    for _ in 0..<Int(countSlider.value) {
      if let properties = eventProperties as? EventProperties {

        // The AppCenterDelegate uses the argument label "withTypedProperties", but the underlying swift API simply uses "withProperties".
        if priority != .Default {
          appCenter.trackEvent(name, withTypedProperties: properties, flags: priority.flags)
        } else {
          appCenter.trackEvent(name, withTypedProperties: properties)
        }
      } else if let dictionary = eventProperties as? [String: String] {
        if priority != .Default {
          appCenter.trackEvent(name, withProperties: dictionary, flags: priority.flags)
        } else {
          appCenter.trackEvent(name, withProperties: dictionary)
        }
      } else {
        if priority != .Default {
          appCenter.trackEvent(name, withTypedProperties: nil, flags: priority.flags)
        } else {
          appCenter.trackEvent(name)
        }
      }
      for targetToken in MSTransmissionTargets.shared.transmissionTargets.keys {
        if MSTransmissionTargets.shared.targetShouldSendAnalyticsEvents(targetToken: targetToken) {
          let target = MSTransmissionTargets.shared.transmissionTargets[targetToken]!
          if let properties = eventProperties as? EventProperties {
            if priority != .Default {
              target.trackEvent(name, withProperties: properties, flags: priority.flags)
            } else {
              target.trackEvent(name, withProperties: properties)
            }
          } else if let dictionary = eventProperties as? [String: String] {
            if priority != .Default {
              target.trackEvent(name, withProperties: dictionary, flags: priority.flags)
            } else {
              target.trackEvent(name, withProperties: dictionary)
            }
          } else {
            if priority != .Default {
              target.trackEvent(name, withProperties: [:], flags: priority.flags)
            } else {
              target.trackEvent(name)
            }
          }
        }
      }
    }
  }

  @IBAction func trackPage() {
    guard let name = eventName.text else {
      return
    }
    appCenter.trackPage(name)
  }

  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setAnalyticsEnabled(sender.isOn)
    sender.isOn = appCenter.isAnalyticsEnabled()
  }

  @IBAction func pause(_ sender: UIButton) {
    appCenter.pause()
  }

  @IBAction func resume(_ sender: UIButton) {
    appCenter.resume()
  }

  @IBAction func countChanged(_ sender: Any) {
    self.countLabel.text = "Count: \(Int(countSlider.value))"
  }

  @IBAction func dismissKeyboard(_ sender: UITextField!) {
    sender.resignFirstResponder()
  }

  func enablePauseResume(enable: Bool) {
    pause.isEnabled = enable
    resume.isEnabled = enable
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? MSAnalyticsResultViewController {
      destination.analyticsResult = analyticsResult
    }
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    eventPropertiesSection.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
  }

  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    if indexPath.section == kEventPropertiesSectionIndex {
      return eventPropertiesSection.tableView(tableView, editingStyleForRowAt: indexPath)
    }
    return .delete
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if indexPath.section == kEventPropertiesSectionIndex && eventPropertiesSection.isInsertRow(indexPath) {
      self.tableView(tableView, commit: .insert, forRowAt: indexPath)
    } else if indexPath.section == 0 && indexPath.row == 3 {
      present(initTransmissionAlert(tableView), animated: true)
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == kEventPropertiesSectionIndex {
      return eventPropertiesSection.tableView(tableView, numberOfRowsInSection: section)
    }
    return super.tableView(tableView, numberOfRowsInSection: section)
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }

  /**
   * Without this override, the default implementation will try to get a table cell that is out of bounds
   * (since they are inserted/removed at a slightly different time than the actual data source is updated).
   */
  override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
    return 0
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if indexPath.section == kEventPropertiesSectionIndex {
      return eventPropertiesSection.tableView(tableView, canEditRowAt:indexPath)
    }
    return false
  }

  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return false
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == kEventPropertiesSectionIndex {
      return eventPropertiesSection.tableView(tableView, cellForRowAt:indexPath)
    }
    return super.tableView(tableView, cellForRowAt: indexPath)
  }
  
  func initTransmissionIntervalLabel() {
    let interval = UserDefaults.standard.integer(forKey: kMSTransmissionIterval)
    updateIntervalLabel(transmissionInterval: interval)
  }
  
  func updateIntervalLabel(transmissionInterval: Int) {
    let formattedInterval = TimeInterval(transmissionInterval)
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.allowedUnits = [ .hour, .minute, .second]
    formatter.zeroFormattingBehavior = [ .pad]
    transmissionIntervalLabel.text = formatter.string(from: formattedInterval)
  }
  
  func initTransmissionAlert(_ tableView: UITableView) -> UIAlertController {
    let alert = UIAlertController(title: "Transmission Interval", message: nil, preferredStyle: .alert)
    let confirmAction = UIAlertAction(title: "OK", style: .default, handler: {(_ action:UIAlertAction) -> Void in
      let result = alert.textFields?[0].text
      let timeResult: Int = Int(result!) ?? 0
      UserDefaults.standard.setValue(timeResult, forKey: kMSTransmissionIterval)
      self.updateIntervalLabel(transmissionInterval: timeResult)
      tableView.reloadData()
    })
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alert.addAction(confirmAction)
    alert.addAction(cancelAction)
    alert.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
      textField.text = String(UserDefaults.standard.integer(forKey: kMSTransmissionIterval))
      textField.keyboardType = UIKeyboardType.numberPad
    })
    return alert
  }
}
