#import "MSPushLog.h"

static NSString *const kMSTypePushInstallationType = @"pushInstallation";
static NSString *const kMSPushToken = @"pushToken";

@implementation MSPushLog

@synthesize type = _type;

- (instancetype)init {
  self = [super init];
  if (self) {
    _type = kMSTypePushInstallationType;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  if (self.pushToken) {
    dict[kMSPushToken] = self.pushToken;
  }
  return dict;
}

- (BOOL)isValid {
  return [super isValid] && self.pushToken;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSPushLog class]] || ![super isEqual:object]) {
    return NO;
  }
  MSPushLog *log = (MSPushLog *)object;
  return ((!self.pushToken && !log.pushToken) || [self.pushToken isEqualToString:log.pushToken]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _type = [coder decodeObjectForKey:kMSTypePushInstallationType];
    _pushToken = [coder decodeObjectForKey:kMSPushToken];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kMSTypePushInstallationType];
  [coder encodeObject:self.pushToken forKey:kMSPushToken];
}

@end
