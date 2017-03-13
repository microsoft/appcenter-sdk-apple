#import "MSErrorBinaryAttachment.h"

static NSString *const kMSFilename = @"file_name";
static NSString *const kMSData = @"data";
static NSString *const kMSContentType = @"content_type";

@implementation MSErrorBinaryAttachment

- (nonnull instancetype)initWithFileName:(nullable NSString *)fileName
                          attachmentData:(nonnull NSData *)data
                             contentType:(nonnull NSString *)contentType {
  if ((self = [super init])) {
    _fileName = fileName;
    _data = data;
    _contentType = contentType;
  }

  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.fileName) {
    dict[kMSFilename] = self.fileName;
  }
  if (self.data) {
    dict[kMSData] = [self.data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
  }
  if (self.contentType) {
    dict[kMSContentType] = self.contentType;
  }

  return dict;
}

- (BOOL)isValid {
  return self.contentType && self.data;
}

- (BOOL)isEqual:(MSErrorBinaryAttachment *)attachment {
  if (!attachment)
    return NO;

  return ((!self.fileName && !attachment.fileName) || [self.fileName isEqualToString:(NSString *_Nonnull)attachment.fileName]) &&
      ((!self.data && !attachment.data) || [self.data isEqual:attachment.data]) &&
      ((!self.contentType && !attachment.contentType) || [self.contentType isEqualToString:attachment.contentType]);
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
  if (self.fileName) {
    [encoder encodeObject:self.fileName forKey:kMSFilename];
  }
  if (self.data) {
    [encoder encodeObject:self.data forKey:kMSData];
  }
  [encoder encodeObject:self.contentType forKey:kMSContentType];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  if ((self = [super init])) {
    _fileName = [decoder decodeObjectForKey:kMSFilename];
    _data = [decoder decodeObjectForKey:kMSData];
    _contentType = [decoder decodeObjectForKey:kMSContentType];
  }
  return self;
}

@end
