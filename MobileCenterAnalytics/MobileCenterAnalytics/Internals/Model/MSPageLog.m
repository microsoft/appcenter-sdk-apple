#import "MSPageLog.h"

static NSString *const kMSTypePage = @"page";

static NSString *const kMSName = @"name";

@implementation MSPageLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSTypePage;
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
  if (!self.name)
    return NO;

  return [super isValid];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _name = [coder decodeObjectForKey:kMSName];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.name forKey:kMSName];
}

@end
