// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation
import UIKit

@objc class Utilities: UIViewController {
    @objc static func topMostController() -> UIViewController? {
        guard
            let window = UIApplication.shared.keyWindow, var topController = window.rootViewController else {
            return nil
        }
        while let newTopController = topController.presentedViewController {
            topController = newTopController
        }
        return topController
    }
}