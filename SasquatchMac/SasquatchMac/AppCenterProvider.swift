// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

@objc class AppCenterProvider:NSObject {

  @objc var appCenter: AppCenterDelegate?

  private static let instance = AppCenterProvider()
  @objc static func shared() -> AppCenterProvider {
    return instance
  }
}
