#import "MSErrorAttachment.h"
#import "MSErrorAttachmentPrivate.h"
#import "MSErrorBinaryAttachment.h"
#import "MSErrorBinaryAttachmentPrivate.h"

static NSString *const kMSTextAttachment = @"text_attachment";
static NSString *const kMSBinaryAttachment = @"binary_attachment";

@implementation MSErrorAttachment

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.textAttachment) {
    dict[kMSTextAttachment] = self.textAttachment;
  }
  if (self.binaryAttachment) {
    dict[kMSBinaryAttachment] = [self.binaryAttachment serializeToDictionary];
  }

  return dict;
}

- (BOOL)isEqual:(MSErrorAttachment *)attachment {
  if (!attachment)
    return NO;

  return ((!self.textAttachment && !attachment.textAttachment) ||
      [self.textAttachment isEqualToString:(NSString *_Nonnull)attachment.textAttachment]) &&
      ((!self.binaryAttachment && !attachment.binaryAttachment) ||
          [self.binaryAttachment isEqual:(MSErrorBinaryAttachment *_Nonnull)attachment.binaryAttachment]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _textAttachment = [coder decodeObjectForKey:kMSTextAttachment];
    _binaryAttachment = [coder decodeObjectForKey:kMSBinaryAttachment];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.textAttachment forKey:kMSTextAttachment];
  [coder encodeObject:self.binaryAttachment forKey:kMSBinaryAttachment];
}

#pragma mark - Public Interface

+ (nonnull MSErrorAttachment *)attachmentWithText:(nonnull NSString *)text {
  MSErrorAttachment *attachment = [MSErrorAttachment new];
  attachment.textAttachment = text;
  return attachment;
}

+ (nonnull MSErrorAttachment *)attachmentWithBinaryData:(nonnull NSData *)data
                                                filename:(nullable NSString *)filename
                                                mimeType:(nonnull NSString *)mimeType {
  MSErrorAttachment *attachment = [MSErrorAttachment new];
  attachment.binaryAttachment =
      [[MSErrorBinaryAttachment alloc] initWithFileName:filename attachmentData:data contentType:mimeType];

  return attachment;
}

+ (nonnull MSErrorAttachment *)attachmentWithText:(nonnull NSString *)text
                                     andBinaryData:(nonnull NSData *)data
                                          filename:(nullable NSString *)filename
                                          mimeType:(nonnull NSString *)mimeType {
  MSErrorAttachment *attachment = [MSErrorAttachment new];
  attachment.textAttachment = text;
  attachment.binaryAttachment =
      [[MSErrorBinaryAttachment alloc] initWithFileName:filename attachmentData:data contentType:mimeType];
  return attachment;
}

@end
