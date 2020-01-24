// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit
import AppCenterDistribute

class MSDistributeViewController: UITableViewController, AppCenterProtocol {

  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var customized: UISwitch!
  @IBOutlet weak var preStartSwitch: UISwitch!
  @IBOutlet weak var updateTrackField: UITextField!
  var appCenter: AppCenterDelegate!

  enum UpdateTrack: String {
     case Public = "Public"
     case Private = "Private"

     var state: MSUpdateTrack {
        switch self {
        case .Public: return .public
        case .Private: return .private
        }
     }

    static func getSelf(by track: MSUpdateTrack) -> UpdateTrack {
       switch track {
       case .public: return .Public
       case .private: return .Private
       }
    }

     static let allValues = [Public, Private]
  }

  private var updatePicker: MSEnumPicker<UpdateTrack>?
  private var updateTrack = UpdateTrack.Public {
    didSet {
       self.updateTrackField.text = self.updateTrack.rawValue
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.customized.isOn = UserDefaults.init().bool(forKey: kSASCustomizedUpdateAlertKey)
    self.preStartSwitch.isOn = UserDefaults.standard.value(forKey: kMSUpdateTrackBeforeStartValue) != nil

    prepareUpdatePicker()

    if let storedTrack = UserDefaults.standard.value(forKey: kMSUpdateTrackBeforeStartValue) as? Int,
       let msTrack = MSUpdateTrack(rawValue: storedTrack) {
        self.updateTrackField.text =  UpdateTrack.getSelf(by: msTrack).rawValue
    }
  }

  private func prepareUpdatePicker() {
    self.updatePicker = MSEnumPicker<UpdateTrack>(
        textField: self.updateTrackField,
        allValues: UpdateTrack.allValues,
        onChange: { index in
            let pickedValue = UpdateTrack.allValues[index]
            if self.preStartSwitch.isOn {
                UserDefaults.standard.set(pickedValue.state.rawValue, forKey: kMSUpdateTrackBeforeStartValue)
            } else {
                MSDistribute.updateTrack = pickedValue.state
                self.updateTrack = pickedValue
            }
    })
    self.updateTrackField.delegate = self.updatePicker
    self.updateTrackField.text = self.updateTrack.rawValue
    self.updateTrackField.tintColor = UIColor.clear
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.enabled.isOn = appCenter.isDistributeEnabled()
    
    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setDistributeEnabled(sender.isOn)
    sender.isOn = appCenter.isDistributeEnabled()
  }

  @IBAction func preStartSwitchUpdated(_ sender: Any) {
    let startTrackValue = preStartSwitch.isOn ? updateTrack.state.rawValue : nil
    UserDefaults.standard.set(startTrackValue, forKey: kMSUpdateTrackBeforeStartValue)
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch (indexPath.section) {
      
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
    UserDefaults.init().set(sender.isOn ? true : false, forKey: kSASCustomizedUpdateAlertKey)
  }
}
