// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Cocoa
import WebKit

extension URL {
    func valueOf(_ queryParamaterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParamaterName })?.value
    }
}

class AuthenticationViewController: NSViewController, WKNavigationDelegate, AnalyticsAuthenticationProviderDelegate {

    var onAuthDataReceived: ((_ token: String, _ userId: String, _ expiresAt: Date) -> Void)?

    enum AuthAction {
        case signin, signout
    }

    var webView: WKWebView!
    var window: NSWindow?

    let baseUrl = "https://login.live.com/oauth20_"
    let redirectEndpoint = "desktop.srf"
    let authorizeEndpoint = "authorize.srf"
    let tokenEndpoint = "token.srf"
    let signOutEndpoint = "logout.srf"
    let clientIdParam = "&client_id=06181c2a-2403-437f-a490-9bcb06f85281"
    let redirectParam = "redirect_uri=https://login.live.com/oauth20_desktop.srf".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    let refreshParam = "&grant_type=refresh_token&refresh_token="
    let refreshTokenParam = "refresh_token"
    let scopeParam = "&scope=service::events.data.microsoft.com::MBI_SSL"
    var refreshToken = ""

    var action: AuthAction = .signin

    enum JSONError: String, Error {
        case NoData = "No data"
        case ConversionFailed = "Conversion from JSON failed"
    }

    override func loadView() {
        super.loadView()
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        if #available(OSX 10.11, *) {
            configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        }
        self.webView = WKWebView(frame: self.view.frame, configuration: configuration)
        self.webView.navigationDelegate = self
        view = self.webView
    }

    override func viewDidAppear() {
        window = self.view.window!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        process()
    }

    func process() {
        switch self.action {
        case .signin:
            self.signinAction()
        case .signout:
            self.signOut()
        }
    }

    func signinAction() {
        NSLog("Started signin process")
        if let signInUrl = URL(string: self.baseUrl + self.authorizeEndpoint + "?" + redirectParam + clientIdParam + "&response_type=token" + scopeParam) {
            self.webView.load(URLRequest(url: signInUrl))
        }
    }

    func signOut() {
        NSLog("Started sign out process")
        if let url = URL(string: self.baseUrl + self.signOutEndpoint + "?" + redirectParam + clientIdParam) {
            self.webView.load(URLRequest(url: url))
        }
    }

    // The sign in flow.
    func signIn(url: URL) {
        if url.absoluteString.contains((self.baseUrl + self.redirectEndpoint)) {
            if let newUrl = URL(string: self.baseUrl + self.redirectEndpoint + "?" + url.fragment!) {
                if let error = newUrl.valueOf("error") {
                    NSLog("Error while signing in: %@", error)
                    self.window?.performClose(nil)
                } else {
                    let refreshToken = newUrl.valueOf(self.refreshTokenParam)!
                    if(!refreshToken.isEmpty) {
                        self.refreshToken = refreshToken
                        NSLog("Successfully signed in with user_id: %@", newUrl.valueOf("user_id")!)

                        // Create a AnalyticsAuthenticationProvider and register as an AnalyticsAuthenticationProvider.
                        let provider = AnalyticsAuthenticationProvider(authenticationType: .msaCompact, ticketKey: newUrl.valueOf("user_id")!, delegate: self)
                        AnalyticsTransmissionTarget.addAuthenticationProvider(authenticationProvider:provider)
                    }
                }
                self.window?.performClose(nil)
            }
        }
    }

    func signOut(url: URL) {
        if url.absoluteString.contains((self.baseUrl + self.redirectEndpoint)) {
            if let error = url.valueOf("error") {
                NSLog("Error while signing out: %@", error)
            } else {
                NSLog("Successfully signed out")
            }
            self.window?.performClose(nil)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        switch action {
        case .signin:
            signIn(url: webView.url!)
        case .signout:
            signOut(url: webView.url!)
        }
    }

    // Implement required method of AnalyticsAuthenticationProviderDelegate protocol.
    func authenticationProvider(_ authenticationProvider: AnalyticsAuthenticationProvider!, acquireTokenWithCompletionHandler completionHandler: AnalyticsAuthenticationProviderCompletionBlock!) {
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
                    self.window?.performClose(nil)
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
                    NSLog("Successfully refreshed token for user: %@", userId)

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
}
