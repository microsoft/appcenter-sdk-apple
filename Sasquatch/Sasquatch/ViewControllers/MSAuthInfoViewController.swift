// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSAuthInfoViewController: UITableViewController {
  
  @IBOutlet weak var accountId: UILabel!
  @IBOutlet weak var accessToken: UILabel!
  @IBOutlet weak var idToken: UILabel!
  
  var userInformation: MSUserInformation?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    updateUserInformation()
  }
  
  func updateUserInformation() {
    var accessTokenDecoded: String = "None"
    var idTokenDecoded: String = "None"
    do {
      let jsonDataAccess = try JSONSerialization.data(withJSONObject: decode(jwtToken: userInformation?.accessToken ?? "None"), options: .prettyPrinted)
      let jsonDataId = try JSONSerialization.data(withJSONObject: decode(jwtToken: userInformation?.idToken ?? "None"), options: .prettyPrinted)
      
      accessTokenDecoded = String.init(data: jsonDataAccess, encoding: .utf8) ?? "None"
      idTokenDecoded = String.init(data: jsonDataId, encoding: .utf8) ?? "None"
    } catch {
      NSLog(error.localizedDescription)
    }
    accountId.text = "Account ID:\n" + (userInformation?.accountId ?? "None")
    accessToken.text = "Access Token:\n" + accessTokenDecoded
    idToken.text = "ID Token:\n" + idTokenDecoded
  }
  
  @IBAction func dismiss(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.destination is MSMainViewController {
      let viewController = segue.destination as? MSMainViewController
      userInformation = viewController?.userInformation
    }
  }
  
  func decode(jwtToken jwt: String) -> [String: Any] {
    let segments = jwt.components(separatedBy: ".")
    return segments.count > 1 ? decodeJWTPart(segments[1]) ?? [:] : [:]
  }
  
  func base64UrlDecode(_ value: String) -> Data? {
    var base64 = value
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    
    let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
    let requiredLength = 4 * ceil(length / 4.0)
    let paddingLength = requiredLength - length
    if paddingLength > 0 {
      let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
      base64 = base64 + padding
    }
    return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
  }
  
  func decodeJWTPart(_ value: String) -> [String: Any]? {
    guard let bodyData = base64UrlDecode(value),
      let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
        return nil
    }
    
    return payload
  }
  
  func close() {
    self.dismiss(animated: true, completion: nil)
  }
}
