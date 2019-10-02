// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation
import AppCenter
import Auth0

class Auth0Provider : NSObject, AuthProviderDelegate {

  private let audienceDomain = "https://appcentersdk.auth0.com/userinfo"
  private var credentialsManager = CredentialsManager(authentication: Auth0.authentication())

  func signIn(_ completionHandler: @escaping (MSUserInformation?, Error?) -> Void) {
    Auth0.webAuth().scope("openid offline_access").audience(audienceDomain).start {
      switch $0 {
      case .failure(let error):
        completionHandler(nil, error)
      case .success(let credentials):
        let userInformation = MSUserInformation()
        userInformation.accessToken = credentials.accessToken
        userInformation.idToken = credentials.idToken
        userInformation.accountId = nil
        self.credentialsManager.store(credentials: credentials)
        completionHandler(userInformation, nil)
      }
    }
  }

  func signOut() {
    self.credentialsManager.clear()
  }

  func appCenter(_ appCenter: MSAppCenter!, acquireAuthTokenWithCompletionHandler completionHandler: MSAuthTokenCompletionHandler!) {
    self.credentialsManager.credentials { error, credentials in
      if error == nil, let credentials = credentials {
        NSLog("Refreshed Auth0 token.")
        self.credentialsManager.store(credentials: credentials)
        completionHandler(credentials.idToken)
      } else {
        NSLog("Failed to refresh Auth0 token.")
        completionHandler(nil)
        return
      }
    }
  }
}
