#import "MSHistoryInfo.h"

static NSString *const kMSTimestampKey = @"timestampKey";

/**
 * This class is a base class for maintaining history of data in time order.
 */
@implementation MSHistoryInfo

- (instancetype)initWithTimestamp:(NSDate *)timestamp {
  self = [super init];
  if (self) {
    _timestamp = timestamp;
  }
  return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _timestamp = [coder decodeObjectForKey:kMSTimestampKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.timestamp forKey:kMSTimestampKey];
}

@end
