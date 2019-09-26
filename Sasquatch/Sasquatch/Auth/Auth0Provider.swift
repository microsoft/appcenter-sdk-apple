// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation
import AppCenter
import Auth0

class Auth0Provider : NSObject, AuthProviderDelegate {
  func signIn(_ completionHandler: @escaping (MSUserInformation?, Error?) -> Void) {
    Auth0.webAuth().scope("openid profile").audience("https://appcentersdk.auth0.com/userinfo").start {
      switch $0 {
      case .failure(let error):
        completionHandler(nil, error)
      case .success(let credentials):
        let userInformation = MSUserInformation()
        userInformation.accessToken = credentials.accessToken;
        userInformation.idToken = credentials.idToken;
        userInformation.accountId = nil;
        completionHandler(userInformation, nil)
      }
    }
  }

  func signOut() {
    MSAppCenter.setAuthToken(nil)
  }

  func appCenter(_ appCenter: MSAppCenter!, acquireAuthTokenWithCompletionHandler completionHandler: MSAuthTokenCompletionHandler!) {
    signIn { (userInformation, error) in
      completionHandler(userInformation?.idToken)
    }
  }
}
