/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMErrorBinaryAttachment.h"

static NSString *const kSNMFilename = @"file_name";
static NSString *const kSNMData = @"data";
static NSString *const kSNMContentType = @"content_type";

@implementation SNMErrorBinaryAttachment

- (nonnull instancetype)initWithFileName:(nullable NSString *)fileName
                          attachmentData:(nonnull NSData *)data
                             contentType:(nonnull NSString *)contentType {
  if (self = [super init]) {
    _fileName = fileName;
    _data = data;
    _contentType = contentType;
  }

  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.fileName) {
    dict[kSNMFilename] = self.fileName;
  }
  if (self.data) {
    dict[kSNMData] = [self.data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
  }
  if (self.contentType) {
    dict[kSNMContentType] = self.contentType;
  }

  return dict;
}

- (BOOL)isValid {
  return self.contentType && self.data;
}

- (BOOL)isEqual:(SNMErrorBinaryAttachment *)attachment {
  if (!attachment)
    return NO;

  return ((!self.fileName && !attachment.fileName) || [self.fileName isEqualToString:attachment.fileName]) &&
      ((!self.data && !attachment.data) || [self.data isEqual:attachment.data]) &&
      ((!self.contentType && !attachment.contentType) || [self.contentType isEqualToString:attachment.contentType]);
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
  if (self.fileName) {
    [encoder encodeObject:self.fileName forKey:kSNMFilename];
  }
  if (self.data) {
    [encoder encodeObject:self.data forKey:kSNMData];
  }
  [encoder encodeObject:self.contentType forKey:kSNMContentType];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  if ((self = [super init])) {
    _fileName = [decoder decodeObjectForKey:kSNMFilename];
    _data = [decoder decodeObjectForKey:kSNMData];
    _contentType = [decoder decodeObjectForKey:kSNMContentType];
  }
  return self;
}

@end
