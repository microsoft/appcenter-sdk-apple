// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation
import AppCenter

@objc protocol AuthProviderDelegate : MSAuthTokenDelegate {
  func signIn(_ completionHandler: @escaping (MSUserInformation?, Error?) -> Void) -> Void;
  func signOut() -> Void;
}
