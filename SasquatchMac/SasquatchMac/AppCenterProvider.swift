// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

@objc class AppCenterProvider:NSObject {

  var appCenter: AppCenterDelegate?

  private static let instance = AppCenterProvider()
  static func shared() -> AppCenterProvider {
    return instance
  }
}
