#import "AVAMockLog.h"

static NSString *const kAVATypeMockLog = @"mockLog";

@implementation AVAMockLog

- (instancetype)init {
  if (self = [super init]) {
    self.type = kAVATypeMockLog;
  }
  return self;
}

- (void)write:(NSMutableDictionary *)dic {
  [super write:dic];
}

- (void)read:(NSDictionary *)obj {
  [super read:obj];
}

- (BOOL)isValid {
  return [super isValid];
}

@end