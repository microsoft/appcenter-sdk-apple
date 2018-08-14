import UIKit
import WebKit

class MSSignInViewController: UIViewController, WKNavigationDelegate {

  var onAuthDataReceived: ((_ token: String, _ userId: String, _ expiresAt: Date) -> Void)?

  enum AuthAction {
    case login, signout
  }

  var webView: WKWebView!

  let baseUrl = "https://login.live.com/oauth20_"
  let redirectEndpoint = "desktop.srf"
  let authorizeEndpoint = "authorize.srf"
  let tokenEndpoint = "token.srf"
  let signOutEndpoint = "logout.srf"
  let clientIdParam = "&client_id=000000004C1D3F6C"
  let redirectParam = "redirect_uri=https://login.live.com/oauth20_desktop.srf".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
  let refreshParam = "&grant_type=refresh_token&refresh_token="
  let refreshTokenParam = "refresh_token"
  let scopeParam = "&scope=service::events.data.microsoft.com::MBI_SSL"
  var refreshToken = ""

  var action: AuthAction = .login

  override func loadView() {
    let configuration = WKWebViewConfiguration()
    configuration.preferences.javaScriptEnabled = true
    configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
    self.webView = WKWebView(frame: .zero, configuration: configuration)
    self.webView.navigationDelegate = self
    view = self.webView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    process()
  }

  func process() {
    switch self.action {
    case .login:
      self.login()
    case .signout:
      self.signOut()
    }
  }

  func login() {
    NSLog("Started login process")
    if let signInUrl = URL(string: self.baseUrl + self.authorizeEndpoint + "?" + redirectParam + clientIdParam + "&response_type=token" + scopeParam) {
      self.webView.load(URLRequest(url: signInUrl))
    }
  }

  enum JSONError: String, Error {
    case NoData = "No data"
    case ConversionFailed = "Conversion from JSON failed"
  }
  
  func refresh() {
    if let refreshUrl = URL(string: self.baseUrl + self.tokenEndpoint) {
      let config = URLSessionConfiguration.default
      let session = URLSession(configuration: config)
      let request = NSMutableURLRequest(url: refreshUrl)
      request.httpMethod = "POST"
      request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
      let bodyString = redirectParam + clientIdParam + refreshParam + refreshToken + scopeParam
      let data: Data = bodyString.data(using: String.Encoding.utf8)!

      NSLog("Started refresh process")
      session.uploadTask(with: request as URLRequest, from: data) { (data, response, error) in
        defer {
          self.close()
        }
        do {
          guard let data = data else {
            throw JSONError.NoData
          }
          guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary else {
            throw JSONError.ConversionFailed
          }
          if let error = json["error"] as? String, let errorDescription = json["error_description"] as? String {
            NSLog("Refresh token error: \"\(error)\": \(errorDescription)")
            return
          }
          let token = json["access_token"]! as! String
          let expiresIn = json["expires_in"]! as! Int64
          let userId = json["user_id"]! as! String
          NSLog("Successfully refreshed token for user: %@ token: %@", userId, token)
          self.onAuthDataReceived?(token, userId, Date().addingTimeInterval(Double(expiresIn)))
        } catch let error as JSONError {
          NSLog("Error while preforming refresh request: %@", error.rawValue)
        } catch let error as NSError {
          NSLog("Error while preforming refresh request: %@", error.localizedDescription)
        }
      }.resume()
    }
  }

  func signOut() {
    NSLog("Started sign out process")
    if let url = URL(string: self.baseUrl + self.signOutEndpoint + "?" + redirectParam + clientIdParam) {
      self.webView.load(URLRequest(url: url))
    }
  }

  func checkSignIn(url: URL) {
    if url.absoluteString.contains((self.baseUrl + self.redirectEndpoint)) {
      if let newUrl = URL(string: self.baseUrl + self.redirectEndpoint + "?" + url.fragment!) {
        if let error = newUrl.valueOf("error") {
          NSLog("Error while signing in: %@", error)
          self.close()
        } else {
          let refreshToken = newUrl.valueOf(self.refreshTokenParam)!
          if(!refreshToken.isEmpty) {
            self.refreshToken = refreshToken
            NSLog("Successfully signed in refresh_token: %@", self.refreshToken)
            self.refresh()
          }
        }
      }
    }
  }

  func checkSignOut(url: URL) {
    if url.absoluteString.contains((self.baseUrl + self.redirectEndpoint)) {
      if let error = url.valueOf("error") {
        NSLog("Error while signing out: %@", error)
      } else {
        NSLog("Successfully signed out")
      }
      close()
    }
  }

  func close() {
    self.dismiss(animated: true, completion: nil)
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    switch action {
    case .login:
      checkSignIn(url: webView.url!)
    case .signout:
      checkSignOut(url: webView.url!)
    }
  }
}

extension URL {
  func valueOf(_ queryParamaterName: String) -> String? {
    guard let url = URLComponents(string: self.absoluteString) else { return nil }
    return url.queryItems?.first(where: { $0.name == queryParamaterName })?.value
  }
}
