// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation
import FBSDKCoreKit
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
      NSLog("SignIn in progress.")
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
    } catch {
      NSLog("SignOut failed.")
    }
  }

  func appCenter(_ appCenter: MSAppCenter!, acquireAuthTokenWithCompletionHandler completionHandler: MSAuthTokenCompletionHandler!) {
    let user = Auth.auth().currentUser;
    if (user == nil) {
      NSLog("Failed to refresh Firebase token as the user is signed out.")
      completionHandler(nil)
    } else {
      user?.getIDToken(completion: { (token, error) in
        if error == nil {
          NSLog("Refreshed Firebase token.")
          completionHandler(token)
        } else {
          NSLog("Failed to refresh Firebase token.")
          completionHandler(nil)
        }
      })
    }
  }

  func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
    if self.completionHandler == nil {
      NSLog("Coulnd't find associated completionHandler for current sign-in request")
      return
    }
    let completionHandler = self.completionHandler
    self.completionHandler = nil
    if error != nil {
      NSLog("Failed to sign-in Firebase.")
      completionHandler!(nil, error)
    } else if user != nil {
      user?.getIDToken(completion: { (token, error) in
        if error == nil {
          NSLog("Received Firebase token.")
          let userInformation = MSUserInformation()
          userInformation.idToken = token
          userInformation.accessToken = AccessToken.current!.tokenString
          completionHandler!(userInformation, nil)
        } else {
          NSLog("Failed to get a token for the user.")
          completionHandler!(nil, error)
        }
      })
    } else {
      NSLog("Failed to get Firebase user.")
      completionHandler!(nil, NSError.init(
          domain: kMSSasquatchErrorDomain,
            code: MSFirebaseAuthUserNotFoundErrorCode,
        userInfo: [NSLocalizedDescriptionKey : "Failed to get Firebase user."]))
    }
  }
}
