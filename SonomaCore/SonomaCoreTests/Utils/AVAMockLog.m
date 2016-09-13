#import "AVAMockLog.h"

static NSString *const kAVATypeMockLog = @"mockLog";

@implementation AVAMockLog

- (instancetype)init {
  if (self = [super init]) {
    self.type = kAVATypeMockLog;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  return dict;
}

@end