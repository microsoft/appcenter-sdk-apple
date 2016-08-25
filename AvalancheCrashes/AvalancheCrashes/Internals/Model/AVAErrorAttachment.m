/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAErrorAttachment.h"

@implementation AVAErrorAttachment

+ (nonnull ErrorAttachment *)attachmentWithText:(nonnull NSString *)text {
  // TODO add implementation
}

+ (nonnull ErrorAttachment *)attachmentWithBinaryData:(nonnull NSData *)data
                                             filename:(nonnull NSString *)filename
                                             mimeType:(nonnull NSString *)mimeType {
  // TODO add implementation
}

+ (nonnull ErrorAttachment *)attachmentWithText:(nonnull NSString *)text
                                  andBinaryData:(nonnull NSData *)data
                                       filename:(nonnull NSString *)filename
                                       mimeType:(nonnull NSString *)mimeType {
  // TODO add implementation
}

+ (nonnull ErrorAttachment *)attachmentWithURL:(nonnull NSURL *)file mimeType:(nullable NSString *)mimeType {
  // TODO add implementation
}

@end
