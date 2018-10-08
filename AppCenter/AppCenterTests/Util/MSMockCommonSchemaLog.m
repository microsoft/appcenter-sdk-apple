#import "MSMockCommonSchemaLog.h"

static NSString *const kMSTypeMockCommonSchemaLog = @"mockCommonSchemaLog";

@implementation MSMockCommonSchemaLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSTypeMockCommonSchemaLog;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  return dict;
}

@end
