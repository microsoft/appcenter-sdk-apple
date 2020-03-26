// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation
import UIKit

class MSAAnalyticsAuthenticationProvider: NSObject, MSAnalyticsAuthenticationProviderDelegate {
    
    private static var _instance: MSAAnalyticsAuthenticationProvider?
    private var refreshToken: String
    private weak var viewController: UIViewController?
    
    enum JSONError: String, Error {
        case NoData = "No data"
        case ConversionFailed = "Conversion from JSON failed"
    }
    
    required init(_ refreshToken: String, _ viewController: UIViewController) {
        self.refreshToken = refreshToken
        self.viewController = viewController
        super.init()
    }
    
    static func getInstance(_ refreshToken: String, _ viewController: UIViewController) -> MSAAnalyticsAuthenticationProvider {
        if let instance = _instance {
            instance.refreshToken = refreshToken
            instance.viewController = viewController
        } else {
            _instance = MSAAnalyticsAuthenticationProvider(refreshToken, viewController)
        }
        return _instance!
    }
    
    // Implement required method of MSanalyticsAuthenticationProviderDelegate protocol.
    func authenticationProvider(_ authenticationProvider: MSAnalyticsAuthenticationProvider!, acquireTokenWithCompletionHandler completionHandler: MSAnalyticsAuthenticationProviderCompletionBlock!) {
        if let refreshUrl = URL(string: kMSABaseUrl + kMSATokenEndpoint) {
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let request = NSMutableURLRequest(url: refreshUrl)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let bodyString = kMSARedirectParam.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + kMSAClientIdParam + kMSARefreshParam + refreshToken + kMSAScopeParam
            let data: Data = bodyString.data(using: String.Encoding.utf8)!
            
            NSLog("Started refresh process")
            session.uploadTask(with: request as URLRequest, from: data) { (data, response, error) in
                defer {
                    self.close()
                }
                do {
                    guard let data = data else {
                        
                        // Call the completion handler in the error case to send anonymous logs.
                        completionHandler(nil, nil)
                        throw JSONError.NoData
                    }
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary else {
                        
                        // Call the completion handler in the error case to send anonymous logs.
                        completionHandler(nil, nil)
                        throw JSONError.ConversionFailed
                    }
                    if let error = json["error"] as? String, let errorDescription = json["error_description"] as? String {
                        NSLog("Refresh token error: \"\(error)\": \(errorDescription)")
                        
                        // Call the completion handler in the error case to send anonymous logs.
                        completionHandler(nil, nil)
                        return
                    }
                    let token = json["access_token"]! as! String
                    let expiresIn = json["expires_in"]! as! Int64
                    let userId = json["user_id"]! as! String
                    NSLog("Successfully refreshed token for user: %@.", userId)
                    UserDefaults.standard.set(userId, forKey: kMSATokenKey)
                    UserDefaults.standard.set(self.refreshToken, forKey: kMSARefreshTokenKey)
                    
                    // Call the completion handler and pass in the updated token and expiryDate.
                    completionHandler(token, Date().addingTimeInterval(Double(expiresIn)))
                } catch let error as JSONError {
                    NSLog("Error while preforming refresh request: %@", error.rawValue)
                } catch let error as NSError {
                    NSLog("Error while preforming refresh request: %@", error.localizedDescription)
                }
                }.resume()
        }
    }
    
    func close() {
        self.viewController?.dismiss(animated: true, completion: nil)
    }
}
