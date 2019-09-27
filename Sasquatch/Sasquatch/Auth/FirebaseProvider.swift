// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

// TODO: Implement Firebase auth
class FirebaseProvider : NSObject, AuthProviderDelegate {
  func signIn(_ completionHandler: @escaping (MSUserInformation?, Error?) -> Void) {
  }

  func signOut() {
  }

  func appCenter(_ appCenter: MSAppCenter!, acquireAuthTokenWithCompletionHandler completionHandler: MSAuthTokenCompletionHandler!) {
  }
}
