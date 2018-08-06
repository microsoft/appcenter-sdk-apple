import UIKit
import MSAL

class MSMicrosoftAuthenticationViewController : UIViewController, AppCenterProtocol {

  let clientID = "06181c2a-2403-437f-a490-9bcb06f85281"
  let scopes = ["User.Read"]
  var appCenter: AppCenterDelegate!
  var application: MSALPublicClientApplication?
  var authenticationResult: MSALResult?

  override func viewDidLoad() {
    super.viewDidLoad()
    application = try? MSALPublicClientApplication.init(clientId: clientID)
  }

  @IBAction func login() {
    application?.acquireToken(forScopes: scopes, completionBlock: authenticationResultHandler())
  }

  @IBAction func refresh() {
    if let result = authenticationResult {
      application?.acquireTokenSilent(forScopes: scopes, account: result.account, completionBlock: authenticationResultHandler())
    }
  }

  @IBAction func dismiss() {
    dismiss(animated: true, completion: nil)
  }

  func updateAuthentication(forAccount: MSALAccount, withAccessToken: String) {

  }

  func authenticationResultHandler() -> MSALCompletionBlock {
    return { (result, error) in
      if error == nil {
        self.authenticationResult = result
        self.updateAuthentication(forAccount: result!.account, withAccessToken: result!.accessToken)
      } else {
        let nserror = error! as NSError
        if nserror.code == MSALErrorCode.interactionRequired.rawValue {
          self.login()
        }
        NSLog("Error during authentication %@", nserror.localizedDescription)
      }
    }
  }
}

