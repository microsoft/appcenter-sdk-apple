// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit
import WebKit

extension URL {
  func valueOf(_ queryParamaterName: String) -> String? {
    guard let url = URLComponents(string: self.absoluteString) else { return nil }
    return url.queryItems?.first(where: { $0.name == queryParamaterName })?.value
  }
}

class MSSignInViewController: UIViewController, WKNavigationDelegate {
  
  var onAuthDataReceived: ((_ token: String, _ userId: String, _ expiresAt: Date) -> Void)?

  enum AuthAction {
    case login, signout
  }
    
  var webView: WKWebView!

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
    if let signInUrl = URL(string: kMSABaseUrl + kMSAAuthorizeEndpoint + "?" + kMSARedirectParam.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + kMSAClientIdParam + "&response_type=token" + kMSAScopeParam) {
      self.webView.load(URLRequest(url: signInUrl))
    }
  }

  func signOut() {
    NSLog("Started sign out process")
    if let url = URL(string: kMSABaseUrl + kMSASignOutEndpoint + "?" + kMSARedirectParam.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + kMSAClientIdParam) {
      self.webView.load(URLRequest(url: url))
    }
  }

  // The sign in flow.
  func signIn(url: URL) {
    if url.absoluteString.contains((kMSABaseUrl + kMSARedirectEndpoint)) {
      if let newUrl = URL(string: kMSABaseUrl + kMSARedirectEndpoint + "?" + url.fragment!) {
        if let error = newUrl.valueOf("error") {
          NSLog("Error while signing in: %@", error)
          self.close()
        } else {
          let refreshToken = newUrl.valueOf(kMSARefreshTokenParam)!
          if(!refreshToken.isEmpty) {
            let userId = newUrl.valueOf("user_id")!
            NSLog("Successfully signed in with user_id: %@.", userId)
            UserDefaults.standard.set(userId, forKey: kMSATokenKey)
            UserDefaults.standard.set(refreshToken, forKey: kMSARefreshTokenKey)
            
            // Create a MSAnalyticsAuthenticationProvider and register as an MSAnalyticsAuthenticationProvider.
            let provider = MSAnalyticsAuthenticationProvider(authenticationType: .msaCompact, ticketKey: userId, delegate: MSAAnalyticsAuthenticationProvider.getInstance(refreshToken, self))
            MSAnalyticsTransmissionTarget.addAuthenticationProvider(authenticationProvider:provider)
          }
        }
      }
    }
  }

  func signOut(url: URL) {
    if url.absoluteString.contains((kMSABaseUrl + kMSARedirectEndpoint)) {
      UserDefaults.standard.removeObject(forKey: kMSATokenKey)
      UserDefaults.standard.removeObject(forKey: kMSARefreshTokenKey)
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
      signIn(url: webView.url!)
    case .signout:
      signOut(url: webView.url!)
    }
  }
}
