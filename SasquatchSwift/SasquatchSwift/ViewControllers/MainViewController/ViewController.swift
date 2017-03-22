//
//  ViewController.swift
//  SasquatchSwift
//
//  Created by Benjamin Reimold on 11/4/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit

import MobileCenter
import MobileCenterAnalytics
import MobileCenterCrashes
import MobileCenterDistribute

class ViewController: UIViewController {
    enum MSCellType : Int {
        case Title, Switch, Details
    }
    
    enum MobileCenterServicesType : Int {
        case Analytics, Crashes, Distribute
        
        var stringValue : String {
            switch self {
            case .Analytics:
                return "Analytics"
            case .Crashes:
                return "Crashes"
            case .Distribute:
                return "Distribute"
            }
        }
        
        static let allServices = [MobileCenterServicesType.Analytics, MobileCenterServicesType.Crashes, MobileCenterServicesType.Distribute]
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

        static let allCases = [MSAnalyticsCases.SetEnabled]
    }

    @IBOutlet weak var tableView: UITableView!
    
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
        if (segue.identifier == "ShowCrashReport" && MSCrashes.hasCrashedInLastSession()){
            (segue.destination as! MSCrashReportViewController).crashReport = MSCrashes.lastSessionCrashReport()
        }
    }
}

extension ViewController : UITableViewDataSource {
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
                    cell.titleSwitch.isOn = MSAnalytics.isEnabled();
                    break;
                case .Crashes:
                    cell.titleSwitch.isOn = MSCrashes.isEnabled();
                    break;
                case .Distribute:
                    cell.titleSwitch.isOn = MSDistribute.isEnabled();
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

extension ViewController : UITableViewDelegate{
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
                MSAnalytics.setEnabled(!MSAnalytics.isEnabled())
                tableView.reloadRows(at: [indexPath], with: .automatic)
                break
            case .TrackEvent:
                //Track event with name only
                MSAnalytics.trackEvent("Row Clicked")
                if (MSAnalytics.isEnabled()) {
                    showAlertWithMessage(title: "Success!", message: "")
                }
                break
            case .TrackEventWithProperties:
                //Track Event with Properties
                MSAnalytics.trackEvent("Row Clicked", withProperties: ["Name" : "Track Event", "Row Number" : "\(indexPath.row)"])
                if (MSAnalytics.isEnabled()) {
                    showAlertWithMessage(title: "Success!", message: "")
                }
                break
            }
            break;
        case .Crashes:
            switch MSCrashesCases.allCases[indexPath.row] {
            case .SetEnabled:
                //Enable/Disable MSCrashes
                MSCrashes.setEnabled(!MSCrashes.isEnabled())
                tableView.reloadRows(at: [indexPath], with: .automatic)
                break
            case .GenerateTestCrash:
                //Test either debugger attached
                if (MSMobileCenter.isDebuggerAttached()) {
                    self.showAlertWithMessage(title: "", message: "Detecting crashes is NOT enabled due to running the app with a debugger attached.")
                } else {
                    //Generate Crash
                    MSCrashes.generateTestCrash()
                }
                break
            case .AppCrashInLastSession:
                //Check either app was crashed in last session
                let message = "App \(MSCrashes.hasCrashedInLastSession() ? "has" : "has not") crashed in last session"
                let alert = MSAlertController.init(title: "", message: message, preferredStyle: .alert)
                if (MSCrashes.hasCrashedInLastSession()) {
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
                MSDistribute.setEnabled(!MSDistribute.isEnabled());
                break;
            default:
                break;
            }
            break;
        }
    }
}

extension ViewController : MSSwitchCellDelegate{
    func switchValueChanged(cell: MSSwitchTableViewCell, sender: UISwitch) {
        guard let section = tableView.indexPath(for: cell)?.section else {
            return;
        }

        guard let serviceType : MobileCenterServicesType = MobileCenterServicesType.init(rawValue: section) else {
            return;
        }

        switch serviceType {
        case .Analytics:
            MSAnalytics.setEnabled(sender.isOn);
            break;
        case .Crashes:
            MSCrashes.setEnabled(sender.isOn);
            break;
        case .Distribute:
            MSDistribute.setEnabled(sender.isOn);
            break;
        }
    }
}
