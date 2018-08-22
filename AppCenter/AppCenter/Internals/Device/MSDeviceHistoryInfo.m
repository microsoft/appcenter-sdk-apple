#import "MSDeviceHistoryInfo.h"

static NSString *const kMSDeviceKey = @"deviceKey";
static NSString *const kMSTimestampKey = @"timestampKey";

@implementation MSDeviceHistoryInfo

- (instancetype)initWithTimestamp:(NSDate *)timestamp
                        andDevice:(MSDevice *)device {
  if ((self = [super init])) {
    _timestamp = timestamp;
    _device = device;
  }
  return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    self.timestamp = [coder decodeObjectForKey:kMSTimestampKey];
    self.device = [coder decodeObjectForKey:kMSDeviceKey];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.timestamp forKey:kMSTimestampKey];
  [coder encodeObject:self.device forKey:kMSDeviceKey];
}

@end
