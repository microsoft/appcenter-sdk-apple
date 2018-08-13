import UIKit

class MSAuthenticationViewController : UITableViewController, AppCenterProtocol {

  var appCenter: AppCenterDelegate!

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @IBAction func login() {

  }

  @IBAction func refresh() {

  }

  @IBAction func dismiss() {
    dismiss(animated: true, completion: nil)
  }

  /*
  let clientID = "06181c2a-2403-437f-a490-9bcb06f85281"
  let scopes = ["User.Read"]

  var application: MSALPublicClientApplication?
  var authenticationResult: MSALResult?

  override func viewDidLoad() {
    super.viewDidLoad()
    if let app = try? MSALPublicClientApplication.init(clientId: clientID) {
      self.application = app
    } else {
      NSLog("Error creating MSALPublicClientApplication object")
    }
  }

  @IBAction func login() {
    application?.acquireToken(forScopes: scopes, completionBlock: authenticationResultHandler())
  }

  @IBAction func refresh() {
    if let result = authenticationResult {
      application?.acquireTokenSilent(forScopes: scopes, user: result.user, completionBlock: authenticationResultHandler())
    }
  }

  @IBAction func dismiss() {
    dismiss(animated: true, completion: nil)
  }

  func updateAuthentication(forUser userId: String, expiryDate: Date, withAccessToken accessToken: String) {
    appCenter.addAuthenticationProvider(withUserId: userId, expiryDate: expiryDate,  andAccessToken: accessToken)
  }

  func authenticationResultHandler() -> MSALCompletionBlock {
    return { (result, error) in
      if error == nil {
        self.authenticationResult = result
        self.updateAuthentication(forUser: result!.user.uid, expiryDate: result!.expiresOn, withAccessToken: result!.accessToken)
        NSLog("Authenticated successfully. User id: %@", result!.user.uid)
      } else {
        let nserror = error! as NSError
        if nserror.code == MSALErrorCode.interactionRequired.rawValue {
          self.login()
        }
        NSLog("Error during authentication %@", nserror.localizedDescription)
      }
    }
  }
 */
}

