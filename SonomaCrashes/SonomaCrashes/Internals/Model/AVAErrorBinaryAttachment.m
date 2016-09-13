/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAErrorBinaryAttachment.h"

static NSString *const kAVAFilename = @"fileName";
static NSString *const kAVAData = @"data";
static NSString *const kAVAContentType = @"contentType";


@implementation AVAErrorBinaryAttachment

- (nonnull instancetype)initWithFileName:(nonnull NSString *)fileName
                  attachmentData:(nonnull NSData *)data
                     contentType:(nullable NSString *)contentType {
  if (self = [super init]) {
    _fileName = fileName;
    _data = data;

    if (contentType) {
      _contentType = contentType;
    } else {
      _contentType = @"application/octet-stream";
    }
  }

  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  
  if (self.fileName) {
    dict[kAVAFilename] = self.fileName;
  }
  if(self.data) {
    dict[kAVAData] = self.data;
  }
  if(self.contentType) {
    dict[kAVAContentType] = self.contentType;
  }
  
  return dict;
}

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)encoder {
  if (self.fileName) {
    [encoder encodeObject:self.fileName forKey:kAVAFilename];
  }
  if (self.data) {
    [encoder encodeObject:self.data forKey:kAVAData];
  }
  [encoder encodeObject:self.contentType forKey:kAVAContentType];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  if ((self = [super init])) {
    _fileName = [decoder decodeObjectForKey:kAVAFilename];
    _data = [decoder decodeObjectForKey:kAVAData];
    _contentType = [decoder decodeObjectForKey:kAVAContentType];
  }
  return self;
}

@end
