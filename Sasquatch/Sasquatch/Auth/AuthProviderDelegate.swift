// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation
import AppCenter

protocol AuthProviderDelegate : MSAuthTokenDelegate {
  func signIn() -> Void;
  func signOut() -> Void;
}
