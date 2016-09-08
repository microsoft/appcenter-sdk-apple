/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAErrorAttachment.h"

static NSString *const kAVATextAttachment = @"textAttachment";
static NSString *const kAVABinaryAttachment = @"binaryAttachment";


@implementation AVAErrorAttachment


- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  
  if (self.textAttachment) {
    dict[kAVATextAttachment] = self.textAttachment;
  }
  if(self.binaryAttachment) {
    dict[kAVABinaryAttachment] = self.binaryAttachment;
  }
  
   return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _textAttachment = [coder decodeObjectForKey:kAVATextAttachment];
    _binaryAttachment = [coder decodeObjectForKey:kAVABinaryAttachment];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.textAttachment forKey:kAVATextAttachment];
  [coder encodeObject:self.binaryAttachment forKey:kAVABinaryAttachment];
}


#pragma mark - Public Interface

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
