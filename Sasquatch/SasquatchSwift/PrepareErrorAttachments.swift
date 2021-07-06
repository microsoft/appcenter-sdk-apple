// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

import CoreLocation
import MobileCoreServices
import Photos
import AppCenterCrashes

class PrepareErrorAttachments: Any {
    
  static func prepareAttachments() -> [ErrorAttachmentLog] {
    var attachments = [ErrorAttachmentLog]()

    // Text attachment.
    let text = UserDefaults.standard.string(forKey: "textAttachment") ?? ""
    if !text.isEmpty {
        let textAttachment = ErrorAttachmentLog.attachment(withText: text, filename: "user.log")!
      attachments.append(textAttachment)
    }

    // Binary attachment.
    let referenceUrl = UserDefaults.standard.url(forKey: "fileAttachment")
    if referenceUrl != nil {
#if !targetEnvironment(macCatalyst)
      let asset = PHAsset.fetchAssets(withALAssetURLs: [referenceUrl!], options: nil).lastObject
      if asset != nil {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        PHImageManager.default().requestImageData(for: asset!, options: options, resultHandler: { (imageData, dataUTI, orientation, info) -> Void in
          let pathExtension = NSURL(fileURLWithPath: dataUTI!).pathExtension
          let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue()
          let mime = UTTypeCopyPreferredTagWithClass(uti!, kUTTagClassMIMEType)?.takeRetainedValue() as NSString?
          let binaryAttachment = ErrorAttachmentLog.attachment(withBinary: imageData, filename: dataUTI, contentType: mime! as String)!
          attachments.append(binaryAttachment)
          print("Add binary attachment with \(imageData?.count ?? 0) bytes")
        })
      }
#else
      do {
        let data = try Data(contentsOf: referenceUrl!)
        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, referenceUrl!.pathExtension as NSString, nil)?.takeRetainedValue()
        let mime = UTTypeCopyPreferredTagWithClass(uti!, kUTTagClassMIMEType)?.takeRetainedValue() as NSString?
        let binaryAttachment = ErrorAttachmentLog.attachment(withBinary: data, filename: referenceUrl?.lastPathComponent, contentType: mime! as String)!
        attachments.append(binaryAttachment)
        print("Add binary attachment with \(data.count) bytes")
      } catch {
        print(error)
      }
#endif
    }
    return attachments
  }
}
