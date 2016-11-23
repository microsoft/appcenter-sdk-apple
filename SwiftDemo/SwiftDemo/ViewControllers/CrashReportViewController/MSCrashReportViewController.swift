//
//  MSCrashReportViewController.swift
//  SwiftDemo
//
//  Created by Vineet Choudhary on 22/11/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit
import MobileCenterCrashes

class MSCrashReportViewController: UIViewController {
    
    enum CrashReport : String {
        case Identifier = "Identifier"
        case ReporterKey = "Reporter Key"
        case Signal = "Signal"
        case ExceptionName = "Exception Name"
        case ExceptionReason = "Exception Reason"
        case AppStartTime = "App Start Time"
        case AppErrorTime = "App Error Time"
        case AppProcessIdentifier = "App Process Identifier"
        case IsAppKill = "Is App Kill"
        case DeviceModel = "Device Model"
        case DeviceOEMName = "Device OEM Name"
        case DeviceOSName = "Device OS Name"
        case DeviceOSVersion = "Device OS Version"
        case DeviceOSBuild = "Device OS Build"
        case DeviceLocale = "Device Locale"
        case DeviceTimeZoneOffset = "Device TimeZone Offset"
        case DeviceScreenSize = "Device Screen Size"
        case AppVersion = "App Version"
        case AppBuild = "App Build"
        case CarrierName = "Carrier Name"
        case CarrierCountry = "Carrier Country"
        case AppNamespace = "App Namespace"
        
        static let allReport  = [CrashReport.Identifier, CrashReport.ReporterKey, CrashReport.Signal, CrashReport.ExceptionName, CrashReport.ExceptionReason, CrashReport.AppStartTime, CrashReport.AppErrorTime, CrashReport.AppProcessIdentifier, CrashReport.IsAppKill, CrashReport.DeviceModel, CrashReport.DeviceOEMName, CrashReport.DeviceOSName, CrashReport.DeviceOSVersion, CrashReport.DeviceOSBuild, CrashReport.DeviceLocale, CrashReport.DeviceTimeZoneOffset, CrashReport.DeviceScreenSize, CrashReport.AppVersion, CrashReport.AppBuild, CrashReport.CarrierName, CrashReport.CarrierCountry, CrashReport.AppNamespace]
    }
    
    @IBOutlet weak var reportTableView: UITableView!
    
    //Get last session crash report
    let report = MSCrashes.lastSessionCrashReport()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Crash Report"
        self.reportTableView.estimatedRowHeight = 50;
        self.reportTableView.rowHeight = UITableViewAutomaticDimension
        self.reportTableView.register(MSDetailsTableViewCell.nib(), forCellReuseIdentifier: MSDetailsTableViewCell.name())
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension MSCrashReportViewController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CrashReport.allReport.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: MSDetailsTableViewCell.name(), for: indexPath) as? MSDetailsTableViewCell{
            switch CrashReport.allReport[indexPath.row] {
            case .Identifier:
                cell.titleNameLabel.text = CrashReport.Identifier.rawValue
                cell.detailLabel.text = report?.incidentIdentifier ?? "N/A"
                break
                
            case .ReporterKey:
                cell.titleNameLabel.text = CrashReport.ReporterKey.rawValue
                cell.detailLabel.text = report?.reporterKey ?? "N/A"
                break
                
            case .Signal:
                cell.titleNameLabel.text = CrashReport.Signal.rawValue
                cell.detailLabel.text = report?.signal ?? "N/A"
                break
                
            case .ExceptionName:
                cell.titleNameLabel.text = CrashReport.ExceptionName.rawValue
                cell.detailLabel.text = report?.exceptionName ?? "N/A"
                break
                
            case .ExceptionReason:
                cell.titleNameLabel.text = CrashReport.ExceptionReason.rawValue
                cell.detailLabel.text = report?.exceptionReason ?? "N/A"
                break
                
            case .AppStartTime:
                cell.titleNameLabel.text = CrashReport.AppStartTime.rawValue
                cell.detailLabel.text = report?.appStartTime.description ?? "N/A"
                break
                
            case .AppErrorTime:
                cell.titleNameLabel.text = CrashReport.AppErrorTime.rawValue
                cell.detailLabel.text = report?.appErrorTime.description ?? "N/A"
                break
                
            case .AppProcessIdentifier:
                cell.titleNameLabel.text = CrashReport.AppProcessIdentifier.rawValue
                cell.detailLabel.text = String(describing: (report!.appProcessIdentifier))
                break
                
            case .IsAppKill:
                cell.titleNameLabel.text = CrashReport.IsAppKill.rawValue
                cell.detailLabel.text = String(describing: report!.isAppKill())
                break
                
            case .DeviceModel:
                cell.titleNameLabel.text = CrashReport.DeviceModel.rawValue
                cell.detailLabel.text = report?.device.model ?? "N/A"
                break
                
            case .DeviceOEMName:
                cell.titleNameLabel.text = CrashReport.DeviceOEMName.rawValue
                cell.detailLabel.text = report?.device.oemName ?? "N/A"
                break
                
            case .DeviceOSName:
                cell.titleNameLabel.text = CrashReport.DeviceOSName.rawValue
                cell.detailLabel.text = report?.device.osName ?? "N/A"
                break
                
            case .DeviceOSVersion:
                cell.titleNameLabel.text = CrashReport.DeviceOSVersion.rawValue
                cell.detailLabel.text = report?.device.osVersion ?? "N/A"
                break
                
            case .DeviceOSBuild:
                cell.titleNameLabel.text = CrashReport.DeviceOSBuild.rawValue
                cell.detailLabel.text = report?.device.osBuild ?? "N/A"
                break
                
            case .DeviceLocale:
                cell.titleNameLabel.text = CrashReport.DeviceLocale.rawValue
                cell.detailLabel.text = report?.device.locale ?? "N/A"
                break
                
            case .DeviceTimeZoneOffset:
                cell.titleNameLabel.text = CrashReport.DeviceTimeZoneOffset.rawValue
                cell.detailLabel.text = String(describing: report!.device.timeZoneOffset)
                break
                
            case .DeviceScreenSize:
                cell.titleNameLabel.text = CrashReport.DeviceScreenSize.rawValue
                cell.detailLabel.text = report?.device.screenSize ?? "N/A"
                break
                
            case .AppVersion:
                cell.titleNameLabel.text = CrashReport.AppVersion.rawValue
                cell.detailLabel.text = report?.device.appVersion ?? "N/A"
                break
                
            case .AppBuild:
                cell.titleNameLabel.text = CrashReport.AppBuild.rawValue
                cell.detailLabel.text = report?.device.appBuild ?? "N/A"
                break
                
            case .CarrierName:
                cell.titleNameLabel.text = CrashReport.CarrierName.rawValue
                cell.detailLabel.text = report?.device.carrierName ?? "N/A"
                break
                
            case .CarrierCountry:
                cell.titleNameLabel.text = CrashReport.CarrierCountry.rawValue
                cell.detailLabel.text = report?.device.carrierCountry ?? "N/A"
                break
                
            case .AppNamespace:
                cell.titleNameLabel.text = CrashReport.AppNamespace.rawValue
                cell.detailLabel.text = report?.device.appNamespace ?? "N/A"
                break
            }
            return cell
        }
        return UITableViewCell()
    }
}

extension MSCrashReportViewController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
