#import "MSCrashesUtil.h"
#import "MSErrorAttachmentLog+Utility.h"
#import "MSErrorAttachmentLogInternal.h"
#import "MSUtility.h"

static NSString *const kMSTextType = @"text/plain";

// API property names.
static NSString *const kMSTypeAttachment = @"errorAttachment";
static NSString *const kMSId = @"id";
static NSString *const kMSErrorId = @"errorId";
static NSString *const kMSContentType = @"contentType";
static NSString *const kMSFileName = @"fileName";
static NSString *const kMSData = @"data";

@implementation MSErrorAttachmentLog

/**
 * @discussion Workaround for exporting symbols from category object files. See article
 * https://medium.com/ios-os-x-development/categories-in-static-libraries-78e41f8ddb96#.aedfl1kl0
 */
__attribute__((used)) static void importCategories() { [NSString stringWithFormat:@"%@", MSMSErrorLogAttachmentLogUtilityCategory]; }

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSTypeAttachment;
    _attachmentId = MS_UUID_STRING;
  }
  return self;
}

- (instancetype)initWithFilename:(nullable NSString *)filename attachmentBinary:(NSData *)data contentType:(NSString *)contentType {
  if ((self = [self init])) {
    _data = data;
    _contentType = contentType;
    _filename = filename;
  }
  return self;
}

- (instancetype)initWithFilename:(nullable NSString *)filename attachmentText:(NSString *)text {
  if ((self = [self init])) {
    self = [self initWithFilename:filename attachmentBinary:[text dataUsingEncoding:NSUTF8StringEncoding] contentType:kMSTextType];
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  // Fill in the dictionary.
  if (self.attachmentId) {
    dict[kMSId] = self.attachmentId;
  }
  if (self.errorId) {
    dict[kMSErrorId] = self.errorId;
  }
  if (self.contentType) {
    dict[kMSContentType] = self.contentType;
  }
  if (self.filename) {
    dict[kMSFileName] = self.filename;
  }
  if (self.data) {
    dict[kMSData] = [self.data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
  }
  return dict;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSErrorAttachmentLog class]] && ![super isEqual:object])
    return NO;
  MSErrorAttachmentLog *attachment = (MSErrorAttachmentLog *)object;
  return ((!self.attachmentId && !attachment.attachmentId) || [self.attachmentId isEqualToString:attachment.attachmentId]) &&
         ((!self.errorId && !attachment.errorId) || [self.errorId isEqualToString:attachment.errorId]) &&
         ((!self.contentType && !attachment.contentType) || [self.contentType isEqualToString:attachment.contentType]) &&
         ((!self.filename && !attachment.filename) || [self.filename isEqualToString:attachment.filename]) &&
         ((!self.data && !attachment.data) || [self.data isEqualToData:attachment.data]);
}

- (BOOL)isValid {
  return [super isValid] && self.errorId && self.attachmentId && self.data && self.contentType;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _attachmentId = [coder decodeObjectForKey:kMSId];
    _errorId = [coder decodeObjectForKey:kMSErrorId];
    _contentType = [coder decodeObjectForKey:kMSContentType];
    _filename = [coder decodeObjectForKey:kMSFileName];
    _data = [coder decodeObjectForKey:kMSData];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.attachmentId forKey:kMSId];
  [coder encodeObject:self.errorId forKey:kMSErrorId];
  [coder encodeObject:self.contentType forKey:kMSContentType];
  [coder encodeObject:self.filename forKey:kMSFileName];
  [coder encodeObject:self.data forKey:kMSData];
}

@end
