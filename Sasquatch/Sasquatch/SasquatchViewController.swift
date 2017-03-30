//
//  ViewController.swift
//  Sasquatch
//
//  Created by Benjamin Reimold on 11/4/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit

class SasquatchViewController: UIViewController {
  enum MSCellType : Int {
    case Title, Switch, Push, Details
  }
  
  enum MobileCenterServicesType : Int {
    case Analytics, Crashes, Distribute, Push
    
    var stringValue : String {
      switch self {
      case .Analytics:
        return "Analytics"
      case .Crashes:
        return "Crashes"
      case .Distribute:
        return "Distribute"
      case .Push:
        return "Push"
      }
    }
    
    static let allServices = [MobileCenterServicesType.Analytics, MobileCenterServicesType.Crashes, MobileCenterServicesType.Distribute, MobileCenterServicesType.Push]
  }
  
  enum MSAnalyticsCases : Int {
    case SetEnabled, TrackEvent, TrackEventWithProperties
    
    var cellSetting : (title:String, type:MSCellType) {
      switch self {
      case .SetEnabled:
        return ("Set Enabled", .Switch)
      case .TrackEvent:
        return ("Track Event", .Details)
      case .TrackEventWithProperties:
        return ("Track Event with Properties", .Details)
      }
    }
    
    static let allCases = [MSAnalyticsCases.SetEnabled, MSAnalyticsCases.TrackEvent, MSAnalyticsCases.TrackEventWithProperties]
  }
  
  enum MSCrashesCases : Int {
    case SetEnabled, GenerateTestCrash, AppCrashInLastSession
    var cellSetting : (title:String, type:MSCellType) {
      switch self {
      case .SetEnabled:
        return ("Set Enabled", .Switch)
      case .GenerateTestCrash:
        return ("Generate Test Crash", .Details)
      case .AppCrashInLastSession:
        return ("App Crash in Last Session", .Details)
      }
    }
    
    static let allCases = [MSCrashesCases.SetEnabled, MSCrashesCases.GenerateTestCrash, MSCrashesCases.AppCrashInLastSession]
  }
  
  enum MSDistributeCases : Int {
    case SetEnabled
    var cellSetting : (title:String, type:MSCellType) {
      switch self {
      case .SetEnabled:
        return ("Set Enabled", .Switch)
      }
    }
    
    static let allCases = [MSDistributeCases.SetEnabled]
  }
  
  enum MSPushCases : Int {
    case SetEnabled
    var cellSetting : (title:String, type:MSCellType) {
      switch self {
      case .SetEnabled:
        return ("Set Enabled", .Switch)
      }
    }

    static let allCases = [MSPushCases.SetEnabled]
  }

  @IBOutlet weak var tableView: UITableView!
  var mobileCenter: MobileCenterDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.estimatedRowHeight = 50;
    self.tableView.sectionHeaderHeight = 50;
    self.tableView.rowHeight = UITableViewAutomaticDimension
    self.tableView.register(MSTitleTableViewCell.nib(), forCellReuseIdentifier: MSTitleTableViewCell.name())
    self.tableView.register(MSSwitchTableViewCell.nib(), forCellReuseIdentifier: MSSwitchTableViewCell.name())
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func showAlertWithMessage(title:String, message:String){
    let alert = MSAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if (segue.identifier == "ShowCrashReport" && mobileCenter.hasCrashedInLastSession()){
      (segue.destination as! MSCrashReportViewController).mobileCenter = mobileCenter
    }
  }
}

extension SasquatchViewController : UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return MobileCenterServicesType.allServices.count
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let serviceType : MobileCenterServicesType = MobileCenterServicesType(rawValue: section) else {
      return 0;
    }
    
    switch serviceType {
    case .Analytics:
      return MSAnalyticsCases.allCases.count
    case .Crashes:
      return MSCrashesCases.allCases.count;
    case .Distribute:
      return MSDistributeCases.allCases.count;
    case .Push:
      return MSPushCases.allCases.count;
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let serviceType : MobileCenterServicesType = MobileCenterServicesType(rawValue: indexPath.section) else {
      return UITableViewCell();
    }
    
    var cellSetting : (title:String, type:MSCellType)? = nil;
    
    switch serviceType {
    case .Analytics:
      cellSetting = MSAnalyticsCases.allCases[indexPath.row].cellSetting;
      break;
    case .Crashes:
      cellSetting = MSCrashesCases.allCases[indexPath.row].cellSetting;
      break;
    case .Distribute:
      cellSetting = MSDistributeCases.allCases[indexPath.row].cellSetting;
      break;
    case .Push:
      cellSetting = MSPushCases.allCases[indexPath.row].cellSetting;
      break;
    }
    
    guard let _cellSetting : (title:String, type:MSCellType) = cellSetting else {
      return UITableViewCell();
    }
    
    if (_cellSetting.type == .Switch) {
      if let cell = tableView.dequeueReusableCell(withIdentifier: MSSwitchTableViewCell.name(), for: indexPath) as? MSSwitchTableViewCell {
        cell.delegate = self
        cell.titleNameLabel.text = _cellSetting.title
        switch serviceType {
        case .Analytics:
          cell.titleSwitch.isOn = mobileCenter.isAnalyticsEnabled()
          break;
        case .Crashes:
          cell.titleSwitch.isOn = mobileCenter.isCrashesEnabled()
          break;
        case .Distribute:
          cell.titleSwitch.isOn = mobileCenter.isDistributeEnabled()
          break;
        case .Push:
          cell.titleSwitch.isOn = mobileCenter.isPushEnabled()
          break;
        }
        return cell;
      }
    } else {
      if let cell = tableView.dequeueReusableCell(withIdentifier: MSTitleTableViewCell.name(), for: indexPath) as? MSTitleTableViewCell {
        cell.titleNameLabel.text = _cellSetting.title
        return cell;
      }
    }
    return UITableViewCell()
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return MobileCenterServicesType(rawValue : section)?.stringValue
  }
}

extension SasquatchViewController : UITableViewDelegate{
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    guard let serviceType : MobileCenterServicesType = MobileCenterServicesType(rawValue: indexPath.section) else {
      return;
    }
    
    switch serviceType {
    case .Analytics:
      switch MSAnalyticsCases.allCases[indexPath.row] {
        
      //Track Event
      case .SetEnabled:
        
        //Enable/Disable MSAnalytics
        mobileCenter.setAnalyticsEnabled(!mobileCenter.isAnalyticsEnabled())
        tableView.reloadRows(at: [indexPath], with: .automatic)
        break
      case .TrackEvent:
        
        //Track event with name only
        mobileCenter.trackEvent("Row Clicked")
        if (mobileCenter.isAnalyticsEnabled()) {
          showAlertWithMessage(title: "Success!", message: "")
        }
        break
      case .TrackEventWithProperties:
        
        //Track Event with Properties
        mobileCenter.trackEvent("Row Clicked", withProperties: ["Name" : "Track Event", "Row Number" : "\(indexPath.row)"])
        if (mobileCenter.isAnalyticsEnabled()) {
          showAlertWithMessage(title: "Success!", message: "")
        }
        break
      }
      break;
    case .Crashes:
      switch MSCrashesCases.allCases[indexPath.row] {
      case .SetEnabled:
        
        //Enable/Disable MSCrashes
        mobileCenter.setCrashesEnabled(!mobileCenter.isCrashesEnabled())
        tableView.reloadRows(at: [indexPath], with: .automatic)
        break
      case .GenerateTestCrash:
        
        //Test either debugger attached
        if (mobileCenter.isDebuggerAttached()) {
          self.showAlertWithMessage(title: "", message: "Detecting crashes is NOT enabled due to running the app with a debugger attached.")
        } else {
          
          //Generate Crash
          mobileCenter.generateTestCrash()
        }
        break
      case .AppCrashInLastSession:
        
        //Check either app was crashed in last session
        let message = "App \(mobileCenter.hasCrashedInLastSession() ? "has" : "has not") crashed in last session"
        let alert = MSAlertController.init(title: "", message: message, preferredStyle: .alert)
        if (mobileCenter.hasCrashedInLastSession()) {
          alert.addAction(UIAlertAction(title: "Show Crash Report", style: .default, handler: { (alert) in
            self.performSegue(withIdentifier: "ShowCrashReport", sender: self)
          }))
        }
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        break
      }
      break;
    case .Distribute:
      switch MSDistributeCases.allCases[indexPath.row] {
      case .SetEnabled:
        
        //Enable/Disable MSDistribute
        mobileCenter.setDistributeEnabled(!mobileCenter.isDistributeEnabled())
        break;
      }
      break;
    case .Push:
      switch MSPushCases.allCases[indexPath.row] {
      case .SetEnabled:

        //Enable/Disable MSPush
        mobileCenter.setPushEnabled(!mobileCenter.isPushEnabled())
        break;
      }
      break;
    }
  }
}

extension SasquatchViewController : MSSwitchCellDelegate{
  func switchValueChanged(cell: MSSwitchTableViewCell, sender: UISwitch) {
    guard let section = tableView.indexPath(for: cell)?.section else {
      return;
    }
    
    guard let serviceType : MobileCenterServicesType = MobileCenterServicesType.init(rawValue: section) else {
      return;
    }
    
    switch serviceType {
    case .Analytics:
      mobileCenter.setAnalyticsEnabled(sender.isOn)
      break;
    case .Crashes:
      mobileCenter.setCrashesEnabled(sender.isOn)
      break;
    case .Distribute:
      mobileCenter.setDistributeEnabled(sender.isOn)
      break;
    case .Push:
      mobileCenter.setPushEnabled(sender.isOn)
      break;
    }
  }
}
