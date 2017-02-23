#import "MSDeviceHistoryInfo.h"

static NSString *const kMSDeviceKey = @"deviceKey";
static NSString *const kMSToffsetKey = @"toffsetKey";

@implementation MSDeviceHistoryInfo

- (instancetype)initWithTOffset:(NSNumber *)tOffset andDevice:(MSDevice *)device {
  if (self = [super init]) {
    _tOffset = tOffset;
    _device = device;
  }
  return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    self.tOffset = [coder decodeObjectForKey:kMSToffsetKey];
    self.device = [coder decodeObjectForKey:kMSDeviceKey];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.tOffset forKey:kMSToffsetKey];
  [coder encodeObject:self.device forKey:kMSDeviceKey];
}

@end