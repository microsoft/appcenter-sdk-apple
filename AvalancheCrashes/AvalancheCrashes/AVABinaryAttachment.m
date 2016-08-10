/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVABinaryAttachment.h"

@implementation AVABinaryAttachment

- (instancetype)initWithFilename:(NSString *)filename
                  attachmentData:(NSData *)data
                     contentType:(NSString *)contentType {
  if (self = [super init]) {
    _filename = filename;
    _data = data;

    if (contentType) {
      _contentType = contentType;
    } else {
      _contentType = @"application/octet-stream";
    }
  }

  return self;
}

#pragma mark - NSCoder

- (void)encodeWithCoder:(NSCoder *)encoder {
  if (self.filename) {
    [encoder encodeObject:self.filename forKey:@"filename"];
  }
  if (self.data) {
    [encoder encodeObject:self.data forKey:@"data"];
  }
  [encoder encodeObject:self.contentType forKey:@"contentType"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  if ((self = [super init])) {
    _filename = [decoder decodeObjectForKey:@"filename"];
    _data = [decoder decodeObjectForKey:@"data"];
    _contentType = [decoder decodeObjectForKey:@"contentType"];
  }
  return self;
}

@end
