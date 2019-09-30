// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation
import FirebaseCore
import FirebaseAuthUI
import FirebaseFacebookAuthUI

typealias CompletionHandler = ((MSUserInformation?, Error?) -> Void)?
class FirebaseProvider : NSObject, AuthProviderDelegate, FUIAuthDelegate {

  private let authUI: FUIAuth?

  private var completionHandler: CompletionHandler

  public override init() {

    // Firebase should be configured before accessing Firebase instances.
    FirebaseApp.configure()

    // AuthUI should be set before super.init.
    self.authUI = FUIAuth.defaultAuthUI()
    super.init()

    self.authUI?.delegate = self
    let providers: [FUIAuthProvider] = [
      FUIFacebookAuth()
    ]
    self.authUI?.providers = providers
  }

  func signIn(_ completionHandler: @escaping (MSUserInformation?, Error?) -> Void) {
    if self.completionHandler != nil {
      NSLog("SignIn in progress")
      return
    }
    self.completionHandler = completionHandler
    let authViewController = self.authUI?.authViewController()
    if var topController = UIApplication.shared.keyWindow?.rootViewController {
      while let presentedViewController = topController.presentedViewController {
        topController = presentedViewController
      }
      topController.present(authViewController!, animated: true, completion: nil)
    }
  }

  func signOut() {
    do {
      try self.authUI?.signOut()
      MSAppCenter.setAuthToken(nil)
    } catch {
      NSLog("SignOut failed")
    }
  }

  func appCenter(_ appCenter: MSAppCenter!, acquireAuthTokenWithCompletionHandler completionHandler: MSAuthTokenCompletionHandler!) {
    signIn { (userInformation, error) in
      completionHandler(userInformation?.idToken)
    }
  }

  func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
    if self.completionHandler == nil {
      NSLog("Coulnd't find associated completionHandler for current signIn request")
      return
    }
    let completionHandler = self.completionHandler
    self.completionHandler = nil
    if error == nil {
      user?.getIDToken(completion: { (token, error) in
        if error == nil {
          let userInformation = MSUserInformation()
          userInformation.idToken = token
          completionHandler!(userInformation, nil)
        } else {
          completionHandler!(nil, error)
        }
      })
    } else {
      completionHandler!(nil, error)
    }
  }
}
