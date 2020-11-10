// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit
import AppCenterDistribute

class MSDistributeViewController: UITableViewController, AppCenterProtocol {

  @IBOutlet weak var autoCheckForUpdate: UISwitch!
  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var customized: UISwitch!
  @IBOutlet weak var updateTrackField: UITextField!
  var appCenter: AppCenterDelegate!

  enum UpdateTrackUpperCase: String, CaseIterable {
    case Public = "Public"
    case Private = "Private"

    var state: UpdateTrack {
       switch self {
       case .Public: return .public
       case .Private: return .private
       }
    }

    static func getSelf(by track: UpdateTrack) -> UpdateTrackUpperCase {
       switch track {
       case .public: return .Public
       case .private: return .Private
       }
    }
  }

  private var updatePicker: MSEnumPicker<UpdateTrackUpperCase>?

  private var updateTrack = UpdateTrackUpperCase.Public {

    didSet {
       self.updateTrackField.text = self.updateTrack.rawValue
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.customized.isOn = UserDefaults.standard.bool(forKey: kSASCustomizedUpdateAlertKey)
    self.autoCheckForUpdate.isOn = UserDefaults.standard.bool(forKey: kSASAutomaticCheckForUpdateDisabledKey)
    preparePickers()
    self.updateTrack = UpdateTrackUpperCase.getSelf(by: Distribute.updateTrack)
  }

  private func preparePickers() {
    self.updatePicker = MSEnumPicker<UpdateTrackUpperCase>(
        textField: self.updateTrackField,
        allValues: UpdateTrackUpperCase.allCases,
        onChange: { index in
            let pickedValue = UpdateTrackUpperCase.allCases[index]
            UserDefaults.standard.set(pickedValue.state.rawValue, forKey: kMSUpdateTrackKey)
    })
    self.updateTrackField.delegate = self.updatePicker
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.enabled.isOn = appCenter.isDistributeEnabled()
    
    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
  }
  
  @IBAction func checkForUpdateSwitchUpdated(_ sender: UISwitch) {
      UserDefaults.standard.set(sender.isOn, forKey: kSASAutomaticCheckForUpdateDisabledKey)
  }
    
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setDistributeEnabled(sender.isOn)
    sender.isOn = appCenter.isDistributeEnabled()
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch (indexPath.section) {
    case 0:
        switch (indexPath.row) {
        case 2: appCenter.checkForUpdate()
        default: ()
        }

    // Section with alerts.
    case 1:
      switch (indexPath.row) {
      case 0:
        if (!customized.isOn) {
          appCenter.showConfirmationAlert()
        } else {
          appCenter.showCustomConfirmationAlert()
        }
      case 1:
        appCenter.showDistributeDisabledAlert()
      default: ()
      }
    default: ()
    }
  }

  @IBAction func customizedSwitchUpdated(_ sender: UISwitch) {
    UserDefaults.standard.set(sender.isOn, forKey: kSASCustomizedUpdateAlertKey)
  }
}
