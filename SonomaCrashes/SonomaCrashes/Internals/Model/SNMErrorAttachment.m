/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMErrorAttachment.h"
#import "SNMErrorAttachmentPrivate.h"
#import "SNMErrorBinaryAttachment.h"
#import "SNMErrorBinaryAttachmentPrivate.h"

static NSString *const kSNMTextAttachment = @"text_attachment";
static NSString *const kSNMBinaryAttachment = @"binary_attachment";

@implementation SNMErrorAttachment

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.textAttachment) {
    dict[kSNMTextAttachment] = self.textAttachment;
  }
  if (self.binaryAttachment) {
    dict[kSNMBinaryAttachment] = [self.binaryAttachment serializeToDictionary];
  }

  return dict;
}

- (BOOL)isEqual:(SNMErrorAttachment *)attachment {
  if (!attachment)
    return NO;

  return ((!self.textAttachment && !attachment.textAttachment) ||
      [self.textAttachment isEqualToString:attachment.textAttachment]) &&
      ((!self.binaryAttachment && !attachment.binaryAttachment) ||
          [self.binaryAttachment isEqual:attachment.binaryAttachment]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _textAttachment = [coder decodeObjectForKey:kSNMTextAttachment];
    _binaryAttachment = [coder decodeObjectForKey:kSNMBinaryAttachment];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.textAttachment forKey:kSNMTextAttachment];
  [coder encodeObject:self.binaryAttachment forKey:kSNMBinaryAttachment];
}

#pragma mark - Public Interface

+ (nonnull SNMErrorAttachment *)attachmentWithText:(nonnull NSString *)text {
  SNMErrorAttachment *attachment = [SNMErrorAttachment new];
  attachment.textAttachment = text;
  return attachment;
}

+ (nonnull SNMErrorAttachment *)attachmentWithBinaryData:(nonnull NSData *)data
                                                filename:(nullable NSString *)filename
                                                mimeType:(nonnull NSString *)mimeType {
  SNMErrorAttachment *attachment = [SNMErrorAttachment new];
  attachment.binaryAttachment =
      [[SNMErrorBinaryAttachment alloc] initWithFileName:filename attachmentData:data contentType:mimeType];

  return attachment;
}

+ (nonnull SNMErrorAttachment *)attachmentWithText:(nonnull NSString *)text
                                     andBinaryData:(nonnull NSData *)data
                                          filename:(nullable NSString *)filename
                                          mimeType:(nonnull NSString *)mimeType {
  SNMErrorAttachment *attachment = [SNMErrorAttachment new];
  attachment.textAttachment = text;
  attachment.binaryAttachment =
      [[SNMErrorBinaryAttachment alloc] initWithFileName:filename attachmentData:data contentType:mimeType];
  return attachment;
}

@end
