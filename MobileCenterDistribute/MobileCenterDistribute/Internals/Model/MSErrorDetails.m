#import "MSErrorDetails.h"

static NSString *const kMSCode = @"code";
static NSString *const kMSMessage = @"message";

@implementation MSErrorDetails

- (instancetype)initWithDictionary:(NSMutableDictionary *)dictionary {
  if ((self = [super init])) {
    if (dictionary[kMSCode]) {
      self.code = dictionary[kMSCode];
    }
    if (dictionary[kMSMessage]) {
      self.message = dictionary[kMSMessage];
    }
  }
  return self;
}

- (BOOL)isValid {
  return (self.code && self.message);
}

@end
