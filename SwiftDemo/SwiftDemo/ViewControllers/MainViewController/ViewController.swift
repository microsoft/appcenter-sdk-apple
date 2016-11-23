//
//  ViewController.swift
//  SwiftDemo
//
//  Created by Benjamin Reimold on 11/4/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit

import MobileCenter
import MobileCenterAnalytics
import MobileCenterCrashes

class ViewController: UIViewController {
    enum MSCellType : Int{
        case Title, Switch, Details
    }
    
    enum MSAnalyticsCases : Int {
        case SetEnabled, TrackEvent, TrackEventWithProperties, TrackPage, TrackPageWithProperties
        
        var cellSetting : (title:String, type:MSCellType){
            switch self {
            case .SetEnabled:
                return ("Set Enabled", .Switch)
            case .TrackEvent:
                return ("Track Event", .Details)
            case .TrackEventWithProperties:
                return ("Track Event with Properties", .Details)
            case .TrackPage:
                return ("Track Page", .Details)
            case .TrackPageWithProperties:
                return ("Track Page with Properties", .Details)
            }
        }
        
        static let allCases = [MSAnalyticsCases.SetEnabled, MSAnalyticsCases.TrackEvent, MSAnalyticsCases.TrackEventWithProperties,MSAnalyticsCases.TrackPage, MSAnalyticsCases.TrackPageWithProperties]
    }
    
    enum MSCrashesCases : Int{
        case SetEnabled, GenerateTestCrash, AppCrashInLastSession
        var cellSetting : (title:String, type:MSCellType){
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
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

}

extension ViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? MSAnalyticsCases.allCases.count : MSCrashesCases.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellSetting = indexPath.section == 0 ?  MSAnalyticsCases.allCases[indexPath.row].cellSetting : MSCrashesCases.allCases[indexPath.row].cellSetting
        if cellSetting.type == .Switch{
            if let cell = tableView.dequeueReusableCell(withIdentifier: MSSwitchTableViewCell.name(), for: indexPath) as? MSSwitchTableViewCell{
                cell.titleNameLabel.text = cellSetting.title
                cell.titleSwitch.isOn = (indexPath.section == 0) ? MSAnalytics.isEnabled() : MSCrashes.isEnabled()
                return cell;
            }
        }else{
            if let cell = tableView.dequeueReusableCell(withIdentifier: MSTitleTableViewCell.name(), for: indexPath) as? MSTitleTableViewCell{
                cell.titleNameLabel.text = cellSetting.title
                return cell;
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return "Analytics"
        }else{
            return "Crashes"
        }
    }
}

extension ViewController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0{
            switch MSAnalyticsCases.allCases[indexPath.row] {
            //Track Event
            case .SetEnabled:
                //Enable/Disable MSAnalytics
                MSAnalytics.setEnabled(!MSAnalytics.isEnabled())
                tableView.reloadRows(at: [indexPath], with: .automatic)
                
            case .TrackEvent:
                //Track event with name only
                MSAnalytics.trackEvent("Row Clicked")
                if MSAnalytics.isEnabled(){
                    showAlertWithMessage(title: "Success!", message: "")
                }
                
            case .TrackEventWithProperties:
                //Track Event with Properties
                MSAnalytics.trackEvent("Row Clicked", withProperties: ["Name" : "Track Event", "Row Number" : "\(indexPath.row)"])
                if MSAnalytics.isEnabled(){
                    showAlertWithMessage(title: "Success!", message: "")
                }
                
            case .TrackPage:
                showAlertWithMessage(title: "Comming Soon!!", message: "")
                
            case .TrackPageWithProperties:
                showAlertWithMessage(title: "Comming Soon!!", message: "")
            }
        }else{
            switch MSCrashesCases.allCases[indexPath.row] {
            case .SetEnabled:
                //Enable/Disable MSCrashes
                MSCrashes.setEnabled(!MSCrashes.isEnabled())
                tableView.reloadRows(at: [indexPath], with: .automatic)

            case .GenerateTestCrash:
                //Test either debugger attached
                if MSMobileCenter.isDebuggerAttached(){
                    self.showAlertWithMessage(title: "", message: "Detecting crashes is NOT enabled due to running the app with a debugger attached.")
                }else{
                    //Generate Crash
                    MSCrashes.generateTestCrash()
                }
            case .AppCrashInLastSession:
                //Check either app was crashed in last session
                let message = "App \(MSCrashes.hasCrashedInLastSession() ? "was" : "wasn't") crashed in last session"
                let alert = UIAlertController.init(title: "", message: message, preferredStyle: .alert)
                if MSCrashes.hasCrashedInLastSession(){
                    
                    alert.addAction(UIAlertAction(title: "Show Chrash Report", style: .default, handler: { (alert) in
                        self.performSegue(withIdentifier: "ShowCrashReport", sender: self)
                    }))
                }
                alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                break
            }
        }
    }
}


extension ViewController : MSSwitchCellDelegate{
    func switchValueChanged(cell: MSSwitchTableViewCell, sender: UISwitch) {
        if (tableView.indexPath(for: cell)?.section == 0){
            MSAnalytics.setEnabled(sender.isOn)
        }else{
            MSCrashes.setEnabled(sender.isOn)
        }
    }
}
