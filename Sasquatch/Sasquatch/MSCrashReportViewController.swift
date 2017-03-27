//
//  MSCrashReportViewController.swift
//  SasquatchSwift
//
//  Created by Vineet Choudhary on 22/11/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import UIKit

class MSCrashReportViewController: UIViewController {
    
    enum CrashReportInfoType : String {
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
        
        static let allReports  = [CrashReportInfoType.Identifier, CrashReportInfoType.ReporterKey, CrashReportInfoType.Signal, CrashReportInfoType.ExceptionName, CrashReportInfoType.ExceptionReason, CrashReportInfoType.AppStartTime, CrashReportInfoType.AppErrorTime, CrashReportInfoType.AppProcessIdentifier, CrashReportInfoType.IsAppKill, CrashReportInfoType.DeviceModel, CrashReportInfoType.DeviceOEMName, CrashReportInfoType.DeviceOSName, CrashReportInfoType.DeviceOSVersion, CrashReportInfoType.DeviceOSBuild, CrashReportInfoType.DeviceLocale, CrashReportInfoType.DeviceTimeZoneOffset, CrashReportInfoType.DeviceScreenSize, CrashReportInfoType.AppVersion, CrashReportInfoType.AppBuild, CrashReportInfoType.CarrierName, CrashReportInfoType.CarrierCountry, CrashReportInfoType.AppNamespace]
    }
    

    @IBOutlet weak var reportTableView: UITableView!
    var mobileCenter:MobileCenterDelegate!
    
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
        return CrashReportInfoType.allReports.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: MSDetailsTableViewCell.name(), for: indexPath) as? MSDetailsTableViewCell{
            switch CrashReportInfoType.allReports[indexPath.row] {
            case .Identifier:
                cell.titleNameLabel.text = CrashReportInfoType.Identifier.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportIncidentIdentifier() ?? "N/A"
                
            case .ReporterKey:
                cell.titleNameLabel.text = CrashReportInfoType.ReporterKey.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportReporterKey() ?? "N/A"
                
            case .Signal:
                cell.titleNameLabel.text = CrashReportInfoType.Signal.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportSignal() ?? "N/A"
                
            case .ExceptionName:
                cell.titleNameLabel.text = CrashReportInfoType.ExceptionName.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportExceptionName() ?? "N/A"
                
            case .ExceptionReason:
                cell.titleNameLabel.text = CrashReportInfoType.ExceptionReason.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportExceptionReason() ?? "N/A"
                
            case .AppStartTime:
                cell.titleNameLabel.text = CrashReportInfoType.AppStartTime.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportAppStartTimeDescription() ?? "N/A"
                
            case .AppErrorTime:
                cell.titleNameLabel.text = CrashReportInfoType.AppErrorTime.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportAppErrorTimeDescription() ?? "N/A"
                
            case .AppProcessIdentifier:
                cell.titleNameLabel.text = CrashReportInfoType.AppProcessIdentifier.rawValue
                cell.detailLabel.text = String(describing: (mobileCenter.lastCrashReportAppProcessIdentifier()))
                
            case .IsAppKill:
                cell.titleNameLabel.text = CrashReportInfoType.IsAppKill.rawValue
                cell.detailLabel.text = String(describing: (mobileCenter.lastCrashReportIsAppKill()))
                break
                
            case .DeviceModel:
                cell.titleNameLabel.text = CrashReportInfoType.DeviceModel.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportDeviceModel() ?? "N/A"
                break
                
            case .DeviceOEMName:
                cell.titleNameLabel.text = CrashReportInfoType.DeviceOEMName.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportDeviceOemName() ?? "N/A"
                break
                
            case .DeviceOSName:
                cell.titleNameLabel.text = CrashReportInfoType.DeviceOSName.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportDeviceOsName() ?? "N/A"
                break
                
            case .DeviceOSVersion:
                cell.titleNameLabel.text = CrashReportInfoType.DeviceOSVersion.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportDeviceOsVersion() ?? "N/A"
                break
                
            case .DeviceOSBuild:
                cell.titleNameLabel.text = CrashReportInfoType.DeviceOSBuild.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportDeviceOsBuild() ?? "N/A"
                break
                
            case .DeviceLocale:
                cell.titleNameLabel.text = CrashReportInfoType.DeviceLocale.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportDeviceLocale() ?? "N/A"
                break
                
            case .DeviceTimeZoneOffset:
                cell.titleNameLabel.text = CrashReportInfoType.DeviceTimeZoneOffset.rawValue
                cell.detailLabel.text = String(describing: mobileCenter.lastCrashReportDeviceTimeZoneOffset() ?? 0)
                break
                
            case .DeviceScreenSize:
                cell.titleNameLabel.text = CrashReportInfoType.DeviceScreenSize.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportDeviceScreenSize() ?? "N/A"
                break
                
            case .AppVersion:
                cell.titleNameLabel.text = CrashReportInfoType.AppVersion.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportDeviceAppVersion() ?? "N/A"
                break
                
            case .AppBuild:
                cell.titleNameLabel.text = CrashReportInfoType.AppBuild.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportDeviceAppBuild() ?? "N/A"
                break
                
            case .CarrierName:
                cell.titleNameLabel.text = CrashReportInfoType.CarrierName.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportDeviceCarrierName() ?? "N/A"
                break
                
            case .CarrierCountry:
                cell.titleNameLabel.text = CrashReportInfoType.CarrierCountry.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportDeviceCarrierCountry() ?? "N/A"
                break
                
            case .AppNamespace:
                cell.titleNameLabel.text = CrashReportInfoType.AppNamespace.rawValue
                cell.detailLabel.text = mobileCenter.lastCrashReportDeviceAppNamespace() ?? "N/A"
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
