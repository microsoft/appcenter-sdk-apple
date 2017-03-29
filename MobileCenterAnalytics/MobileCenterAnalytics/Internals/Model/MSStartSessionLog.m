#import "MSStartSessionLog.h"

static NSString *const kMSTypeEndSession = @"start_session";

@implementation MSStartSessionLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSTypeEndSession;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
}

@end
