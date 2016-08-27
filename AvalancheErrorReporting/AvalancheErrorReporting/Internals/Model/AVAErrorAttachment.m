/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAErrorAttachment.h"

@implementation AVAErrorAttachment

+ (nonnull AVAErrorAttachment *)attachmentWithText:(nonnull NSString *)text {
  // TODO add implementation
  return [AVAErrorAttachment new];
}

+ (nonnull AVAErrorAttachment *)attachmentWithBinaryData:(nonnull NSData *)data
                                             filename:(nonnull NSString *)filename
                                             mimeType:(nonnull NSString *)mimeType {
  // TODO add implementation
  return [AVAErrorAttachment new];

}

+ (nonnull AVAErrorAttachment *)attachmentWithText:(nonnull NSString *)text
                                  andBinaryData:(nonnull NSData *)data
                                       filename:(nonnull NSString *)filename
                                       mimeType:(nonnull NSString *)mimeType {
  // TODO add implementation
  return [AVAErrorAttachment new];

}

+ (nonnull AVAErrorAttachment *)attachmentWithURL:(nonnull NSURL *)file mimeType:(nullable NSString *)mimeType {
  // TODO add implementation
  return [AVAErrorAttachment new];
}

@end
