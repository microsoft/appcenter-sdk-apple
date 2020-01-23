// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSDistributeViewController: UITableViewController, AppCenterProtocol {

  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var customized: UISwitch!
  @IBOutlet weak var updateTrackField: UITextField!
  var appCenter: AppCenterDelegate!

  enum UpdateTrack: String {
     case Public = "Public"
     case Private = "Private"

     var updateTrack: MSUpdateTrack {
        switch self {
        case .Public: return .public
        case .Private: return .private
        }
     }

     static let allValues = [Public, Private]
  }

  private var updatePicker: MSEnumPicker<UpdateTrack>?
  private var updateTrack = UpdateTrack.Public {
    didSet {
       MSDistribute.updateTrack = updateTrack.updateTrack
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.customized.isOn = UserDefaults.init().bool(forKey: kSASCustomizedUpdateAlertKey)

    self.updatePicker = MSEnumPicker<UpdateTrack>(
        textField: self.updateTrackField,
        allValues: UpdateTrack.allValues,
        onChange: { index in self.updateTrack = UpdateTrack.allValues[index] })
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
