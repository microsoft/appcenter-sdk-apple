#import "MSDeviceHistoryInfo.h"

static NSString *const kMSDeviceKey = @"deviceKey";

/**
 * This class is used to associate device properties with the timestamp that it was created with.
 */
@implementation MSDeviceHistoryInfo

- (instancetype)initWithTimestamp:(NSDate *)timestamp andDevice:(MSDevice *)device {
  self = [super initWithTimestamp:timestamp];
  if (self) {
    _device = device;
  }
  return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.device = [coder decodeObjectForKey:kMSDeviceKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.device forKey:kMSDeviceKey];
}

@end
