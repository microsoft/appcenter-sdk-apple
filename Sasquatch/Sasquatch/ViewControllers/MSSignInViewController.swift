import UIKit
import WebKit

class MSSignInViewController: UIViewController, WKNavigationDelegate {

  var webView: WKWebView!

  let redirectUrl = "https://login.live.com/oauth20_desktop.srf"
  let authorizeUrl = "https://login.live.com/oauth20_authorize.srf?"
  let signOutUrl = "https://login.live.com/oauth20_logout.srf?"
  let clientId = "000000004C1D3F6C"
  let scope = "service::events.data.microsoft.com::MBI_SSL"
  lazy var clientIdParam = { return "&client_id=" + self.clientId }()
  lazy var redirectParam = { return "redirect_uri=" + self.redirectUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! }()
  lazy var scopeParam = { return "&scope=" + self.scope }()

  override func loadView() {
    let configuration = WKWebViewConfiguration()
    configuration.preferences.javaScriptEnabled = true
    webView = WKWebView(frame: .zero, configuration: configuration)
    webView.navigationDelegate = self
    view = webView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    if let signInUrl = URL(string: authorizeUrl + redirectParam + clientIdParam + "&response_type=token" + scopeParam) {
      webView.load(URLRequest(url: signInUrl))
    }
  }

  func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
    print("redirect to")
    print(webView.url!)
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    print("finish loading")
    print(webView.url!)
  }
}
