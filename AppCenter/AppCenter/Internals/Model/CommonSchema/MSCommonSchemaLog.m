#import "MSCommonSchemaLog.h"

static NSString *const kMSCommonSchemaVer = @"3.0";

@implementation MSCommonSchemaLog

- (id)init {
  if ((self = [super init])) {
    _ver = kMSCommonSchemaVer;
    _popSample = 100.0;
  }
  return self;
}

@end
