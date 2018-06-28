//
//  MSAnalyticsChildTransmissionTargetTableViewController.swift
//  SasquatchObjC
//
//  Created by Benjamin Scholtysik on 6/28/18.
//  Copyright © 2018 Microsoft Corp. All rights reserved.
//

import UIKit

class MSAnalyticsChildTransmissionTargetTableViewController: UITableViewController, AppCenterProtocol {
  var appCenter: AppCenterDelegate!
  @IBOutlet weak var childToken1Label: UILabel!
  @IBOutlet weak var childToken2Label: UILabel!
  
    override func viewDidLoad() {
      super.viewDidLoad()
      self.childToken1Label.text = "Child Target Token 1 - 602c2d52"
      self.childToken2Label.text = "Child Target Token 2 - 902923eb"
    }
  
    // MARK: - Table view data source

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.row {
    case 0:
      UserDefaults.standard.setValue(nil, forKey: kMSChildTransmissionTargetTokenKey)
      self.navigationController?.popViewController(animated: true)
      break
    case 1:
      UserDefaults.standard.setValue("602c2d529a824339bef93a7b9a035e6a-a0189496-cc3a-41c6-9214-b479e5f44912-6819", forKey: kMSChildTransmissionTargetTokenKey)
      self.navigationController?.popViewController(animated: true)
      break
    case 2:
      UserDefaults.standard.setValue("902923ebd7a34552bd7a0c33207611ab-a48969f4-4823-428f-a88c-eff15e474137-7039", forKey: kMSChildTransmissionTargetTokenKey)
      self.navigationController?.popViewController(animated: true)
    default:
      break
    }
  }
}
