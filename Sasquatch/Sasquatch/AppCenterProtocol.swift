// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

/**
 * Protocol that all ViewControllers interacting with AppCenter should implement.
 */
@objc protocol AppCenterProtocol : class {
  var appCenter : AppCenterDelegate! { get set }
}
