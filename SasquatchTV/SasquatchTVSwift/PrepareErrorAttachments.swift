// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation
import AppCenterCrashes;

class PrepareErrorAttachments: Any {
    
  static func prepareAttachments() -> [ErrorAttachmentLog] {
    let attachment1 = ErrorAttachmentLog.attachment(withText: "Hello world!", filename: "hello.txt")
    let attachment2 = ErrorAttachmentLog.attachment(withBinary: "Fake image".data(using: String.Encoding.utf8), filename: nil, contentType: "image/jpeg")
    return [attachment1!, attachment2!]
  }
}
