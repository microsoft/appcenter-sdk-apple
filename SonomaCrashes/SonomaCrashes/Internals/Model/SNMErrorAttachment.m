/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMErrorAttachment.h"

static NSString *const kSNMTextAttachment = @"textAttachment";
static NSString *const kSNMBinaryAttachment = @"binaryAttachment";


@implementation SNMErrorAttachment


- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  
  if (self.textAttachment) {
    dict[kSNMTextAttachment] = self.textAttachment;
  }
  if(self.binaryAttachment) {
    dict[kSNMBinaryAttachment] = self.binaryAttachment;
  }
  
   return dict;
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
  // TODO add implementation
  return [SNMErrorAttachment new];
}

+ (nonnull SNMErrorAttachment *)attachmentWithBinaryData:(nonnull NSData *)data
                                             filename:(nonnull NSString *)filename
                                             mimeType:(nonnull NSString *)mimeType {
  // TODO add implementation
  return [SNMErrorAttachment new];

}

+ (nonnull SNMErrorAttachment *)attachmentWithText:(nonnull NSString *)text
                                  andBinaryData:(nonnull NSData *)data
                                       filename:(nonnull NSString *)filename
                                       mimeType:(nonnull NSString *)mimeType {
  // TODO add implementation
  return [SNMErrorAttachment new];

}

+ (nonnull SNMErrorAttachment *)attachmentWithURL:(nonnull NSURL *)file mimeType:(nullable NSString *)mimeType {
  // TODO add implementation
  return [SNMErrorAttachment new];
}

@end
