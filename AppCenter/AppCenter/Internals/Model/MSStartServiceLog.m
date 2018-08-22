#import "MSStartServiceLog.h"

static NSString *const kMSStartService = @"startService";
static NSString *const kMSServices = @"services";

@implementation MSStartServiceLog

@synthesize services = _services;

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSStartService;
  }
  return self;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSStartServiceLog class]] ||
      ![super isEqual:object]) {
    return NO;
  }
  MSStartServiceLog *log = (MSStartServiceLog *)object;
  return ((!self.services && !log.services) ||
          [self.services isEqualToArray:log.services]);
}

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  if (self.services) {
    dict[kMSServices] = self.services;
  }
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super initWithCoder:coder])) {
    self.services = [coder decodeObjectForKey:kMSServices];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.services forKey:kMSServices];
}

@end
