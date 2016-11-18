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

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    enum TestCase : String {
        case TrackEvent = "Track Event"
        case GenerateTestCrash = "Generate Test Crash"
        case EnableDisableCrashes = "Enable or disable Crashes"
        case EnableDisableAnalytics = "Enable or disable Analytics"
        case AppCrashInLastSession = "App crash in the last session?"
        
        static let allCases = [TestCase.TrackEvent, TestCase.GenerateTestCrash, TestCase.EnableDisableCrashes, TestCase.EnableDisableAnalytics, TestCase.AppCrashInLastSession]
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell()))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UITableView DetaSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TestCase.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        cell.textLabel?.text = TestCase.allCases[indexPath.row].rawValue
        return cell;
    }
    
    //MARK: - UITableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch TestCase.allCases[indexPath.row] {
        //Track Event
        case .TrackEvent:
            //Track event with name and properties
            MSAnalytics.trackEvent("Row Clicked", withProperties: ["Name" : "Track Event", "Row Number" : "\(indexPath.row)"])
            
            //Track event with name only
            MSAnalytics.trackEvent("Row Clicked")
            
            self.showAlertWithMessage(title: "MSAnalytics", message: "\(MSAnalytics.isEnabled() ? "Tracking Event!!" : "MSAnalytics Disabled.")")
            
        //Generate Test Crash
        case .GenerateTestCrash:
            //Test either debugger attached
            if MSMobileCenter.isDebuggerAttached(){
                self.showAlertWithMessage(title: "", message: "Detecting crashes is NOT enabled due to running the app with a debugger attached.")
            }else{
                //Generate Crash
                MSCrashes.generateTestCrash()
            }
            
        case .EnableDisableCrashes:
            //Enable/Disable MSCrashes
            MSCrashes.setEnabled(!MSCrashes.isEnabled())
            self.showAlertWithMessage(title: "MSCrashes", message: "\(MSCrashes.isEnabled() ? "Enabled" : "Disabled")")
            
        case .EnableDisableAnalytics:
            //Enable/Disable MSAnalytics
            MSAnalytics.setEnabled(!MSAnalytics.isEnabled())
            self.showAlertWithMessage(title: "MSAnalytics", message: "\(MSAnalytics.isEnabled() ? "Enabled" : "Disabled")")
            
        case .AppCrashInLastSession:
            //Check either app was crashed in last session
            let message = "App \(MSCrashes.hasCrashedInLastSession() ? "was" : "wasn't") crashed in last session"
            let alert = UIAlertController.init(title: "", message: message, preferredStyle: .alert)
            if MSCrashes.hasCrashedInLastSession(){
                alert.addAction(UIAlertAction(title: "Show Description", style: .default, handler: { (alert) in
                    
                    //Get last session crash report
                    let report = MSCrashes.lastSessionCrashReport()
                    var message = ""
                    if let appVersion = report?.device.appVersion{
                        message.append("App Version - \(appVersion) \n\n")
                    }
                    if let appErrorTime = report?.appErrorTime{
                        message.append("App Error Time - \(appErrorTime) \n\n")
                    }
                    if let appStartTime = report?.appStartTime{
                        message.append("App Start Time - \(appStartTime) \n\n")
                    }
                    message.append("MSCrashes.lastSessionCrashReport() will provides you more details about the crash that occurred in the last app session")
                    self.showAlertWithMessage(title: "Last Session Crash Report", message: message)
                }))
            }
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: - Helper Methods
    private func showAlertWithMessage(title:String, message:String){
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

}
