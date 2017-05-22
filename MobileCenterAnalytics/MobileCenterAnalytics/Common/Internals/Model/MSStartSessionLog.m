#import "MSStartSessionLog.h"

static NSString *const kMSTypeEndSession = @"start_session";

@implementation MSStartSessionLog

@synthesize type = _type;

- (instancetype)init {
  if ((self = [super init])) {
    _type = kMSTypeEndSession;
  }
  return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _type = [coder decodeObjectForKey:kMSType];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kMSType];
}

@end
