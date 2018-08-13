import UIKit
import WebKit

class MSSignInViewController: UIViewController, WKNavigationDelegate {

  var onAuthDataRecieved: ((_ token: String, _ userId: String, _ expiresAt: Date) -> Void)?

  enum AuthAction {
    case login, refresh, signout
  }

  var webView: WKWebView!

  let baseUrl = "https://login.live.com"
  let redirectEndpoint = "/oauth20_desktop.srf"
  let authorizeEndpoint = "/oauth20_authorize.srf"
  let signOutEndpoint = "/oauth20_logout.srf"
  let clientId = "000000004C1D3F6C"
  let scope = "service::events.data.microsoft.com::MBI_SSL"
  lazy var clientIdParam = { return "&client_id=" + self.clientId }()
  lazy var redirectParam = { return "redirect_uri=" + (self.baseUrl + self.redirectEndpoint).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! }()
  lazy var scopeParam = { return "&scope=" + self.scope }()

  var action: AuthAction = .login

  override func loadView() {
    let configuration = WKWebViewConfiguration()
    configuration.preferences.javaScriptEnabled = true
    webView = WKWebView(frame: .zero, configuration: configuration)
    webView.navigationDelegate = self
    view = webView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    process()
  }

  func process() {
    switch action {
    case .login:
      login()
    case .refresh:
      refresh()
    case .signout:
      signOut()
    }
  }

  func login() {
    if let signInUrl = URL(string: self.baseUrl + self.authorizeEndpoint + "?" + redirectParam + clientIdParam + "&response_type=token" + scopeParam) {
      webView.load(URLRequest(url: signInUrl))
    }
  }

  func refresh() {

  }

  func signOut() {
    if let url = URL(string: self.baseUrl + self.signOutEndpoint + "?" + redirectParam + clientIdParam) {
      webView.load(URLRequest(url: url))
    }
  }

  func checkSignIn(url: URL) {
    if url.absoluteString.starts(with: (self.baseUrl + self.redirectEndpoint)) {
      if let newUrl = URL(string: self.baseUrl + self.redirectEndpoint + "?" + url.fragment!) {
        let token = newUrl.valueOf("access_token")!
        let userId = newUrl.valueOf("user_id")!
        let expiresIn = Int64(newUrl.valueOf("expires_in")!)!

        onAuthDataRecieved?(token, userId, Date().addingTimeInterval(Double(expiresIn)))
      }
      close()
    }
  }

  func checkSignOut(url: URL) {
    if url.absoluteString.starts(with: (self.baseUrl + self.redirectEndpoint)) {
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
    case .refresh:
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
