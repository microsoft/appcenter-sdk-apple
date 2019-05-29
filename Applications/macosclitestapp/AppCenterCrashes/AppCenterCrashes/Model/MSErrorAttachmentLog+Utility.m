// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSErrorAttachmentLog+Utility.h"

// Exporting symbols for category.
NSString *MSMSErrorLogAttachmentLogUtilityCategory;

// This category is used to avoid adding more logic than needed to the model implementation file.
@implementation MSErrorAttachmentLog (Utility)

+ (nonnull MSErrorAttachmentLog *)attachmentWithText:(nonnull NSString *)text filename:(nullable NSString *)filename {
  return [[MSErrorAttachmentLog alloc] initWithFilename:filename attachmentText:text];
}

+ (nonnull MSErrorAttachmentLog *)attachmentWithBinary:(nonnull NSData *)data
                                              filename:(nullable NSString *)filename
                                           contentType:(nonnull NSString *)contentType {
  return [[MSErrorAttachmentLog alloc] initWithFilename:filename attachmentBinary:data contentType:contentType];
}

@end
