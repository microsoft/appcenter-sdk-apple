// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit
import AppCenterDistribute

class MSDistributeViewController: UITableViewController, AppCenterProtocol {

  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var customized: UISwitch!
  @IBOutlet weak var whenUpdateTrackField: UITextField!
  @IBOutlet weak var updateTrackField: UITextField!
  var appCenter: AppCenterDelegate!

  enum UpdateTrack: String, CaseIterable {
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
  }

  enum WhenUpdateTrack: String, CaseIterable {
    case now = "Now"
    case beforeNextStart = "Before next start"
  }

  private var updatePicker: MSEnumPicker<UpdateTrack>?
  private var whenUpdateTrackPicker: MSEnumPicker<WhenUpdateTrack>?
  private var updateTrack = UpdateTrack.Public {
    didSet {
       self.updateTrackField.text = self.updateTrack.rawValue
    }
  }
  private var whenUpdateTrack = WhenUpdateTrack.now {
    didSet {
        self.whenUpdateTrackField.text = self.whenUpdateTrack.rawValue
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.customized.isOn = UserDefaults.init().bool(forKey: kSASCustomizedUpdateAlertKey)
    preparePickers()
    self.updateTrack = UpdateTrack.getSelf(by: MSDistribute.updateTrack)
    if UserDefaults.standard.value(forKey: kMSUpdateTrackBeforeStartValue) != nil {
        self.whenUpdateTrack = .beforeNextStart
    }
  }

  private func preparePickers() {
    self.updatePicker = MSEnumPicker<UpdateTrack>(
        textField: self.updateTrackField,
        allValues: UpdateTrack.allCases,
        onChange: { index in
            let pickedValue = UpdateTrack.allCases[index]
            switch self.whenUpdateTrack {
            case .beforeNextStart:
                UserDefaults.standard.set(pickedValue.state.rawValue, forKey: kMSUpdateTrackBeforeStartValue)
            case .now:
                MSDistribute.updateTrack = pickedValue.state
                self.updateTrack = pickedValue
            }
    })
    self.whenUpdateTrackPicker = MSEnumPicker<WhenUpdateTrack>(
        textField: self.whenUpdateTrackField,
        allValues: WhenUpdateTrack.allCases,
        onChange: { index in
            self.whenUpdateTrack = WhenUpdateTrack.allCases[index]
            var startTrackValue: Int?
            switch self.whenUpdateTrack {
            case .beforeNextStart:
                startTrackValue = UpdateTrack.getSelf(by: MSDistribute.updateTrack).state.rawValue
            case .now:
                startTrackValue = nil
            }
            UserDefaults.standard.set(startTrackValue, forKey: kMSUpdateTrackBeforeStartValue)
    })
    self.updateTrackField.delegate = self.updatePicker
    self.whenUpdateTrackField.delegate = self.whenUpdateTrackPicker
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
