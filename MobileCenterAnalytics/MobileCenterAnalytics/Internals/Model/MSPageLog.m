#import "MSPageLog.h"

static NSString *const kMSTypePage = @"page";

static NSString *const kMSName = @"name";

@implementation MSPageLog

@synthesize type = _type;

- (instancetype)init {
  if ((self = [super init])) {
    _type = kMSTypePage;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.name) {
    dict[kMSName] = self.name;
  }
  return dict;
}

- (BOOL)isValid {
  return [super isValid] && self.name;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSPageLog class]] || ![super isEqual:object]) {
    return NO;
  }
  MSPageLog *pageLog = (MSPageLog *)object;
  return ((!self.name && !pageLog.name) || [self.name isEqualToString:pageLog.name]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _type = [coder decodeObjectForKey:kMSType];
    _name = [coder decodeObjectForKey:kMSName];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kMSType];
  [coder encodeObject:self.name forKey:kMSName];
}

@end
