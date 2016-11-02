#import "MSMockLog.h"

static NSString *const kSNMTypeMockLog = @"mockLog";

@implementation MSMockLog

- (instancetype)init {
  if (self = [super init]) {
    self.type = kSNMTypeMockLog;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  return dict;
}

@end
