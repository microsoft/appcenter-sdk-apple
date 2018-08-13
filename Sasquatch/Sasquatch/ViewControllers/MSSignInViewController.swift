import UIKit
import WebKit

class MSSignInViewController: UIViewController, WKNavigationDelegate {


  var onAuthDataRecieved: ((_ token: String, _ userId: String, _ expiresAt: Date) -> Void)?

  enum AuthAction {
    case login, refresh, signout
  }

  var webView: WKWebView!

  let redirectUrl = "https://login.live.com/oauth20_desktop.srf"
  let authorizeUrl = "https://login.live.com/oauth20_authorize.srf?"
  let signOutUrl = "https://login.live.com/oauth20_logout.srf?"
  let clientId = "000000004C1D3F6C"
  let scope = "service::events.data.microsoft.com::MBI_SSL"
  lazy var clientIdParam = { return "&client_id=" + self.clientId }()
  lazy var redirectParam = { return "redirect_uri=" + self.redirectUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! }()
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
    if let signInUrl = URL(string: authorizeUrl + redirectParam + clientIdParam + "&response_type=token" + scopeParam) {
      webView.load(URLRequest(url: signInUrl))
    }
  }

  func refresh() {

  }

  func signOut() {
    if let signOutUrl = URL(string: signOutUrl + redirectParam + clientIdParam) {
      webView.load(URLRequest(url: signOutUrl))
    }
  }

  func checkSignIn(url: URL) {
    if url.absoluteString.starts(with: redirectUrl) {
      if let newUrl = URL(string: redirectUrl + "?" + url.fragment!) {
        let token = newUrl.valueOf("access_token")!
        let userId = newUrl.valueOf("user_id")!
        let expiresIn = Int64(newUrl.valueOf("expires_in")!)!

        onAuthDataRecieved?(token, userId, Date().addingTimeInterval(Double(expiresIn)))
      }
      close()
    }
  }

  func checkSignOut(url: URL) {
    if url.absoluteString.starts(with: redirectUrl) {
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
