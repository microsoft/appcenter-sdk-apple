#import "MSSessionHistoryInfo.h"

static NSString *const kMSSessionIdKey = @"sessionIdKey";
static NSString *const kMSTimestampKey = @"timestampKey";

/**
 * This class is used to associate session id with the timestamp that it was
 * created.
 */
@implementation MSSessionHistoryInfo

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _sessionId = [coder decodeObjectForKey:kMSSessionIdKey];
    _timestamp = [coder decodeObjectForKey:kMSTimestampKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.sessionId forKey:kMSSessionIdKey];
  [coder encodeObject:self.timestamp forKey:kMSTimestampKey];
}

- (instancetype)initWithTimestamp:(NSDate *)timestamp
                     andSessionId:(NSString *)sessionId {
  self = [super init];
  if (self) {
    _sessionId = sessionId;
    _timestamp = timestamp;
  }
  return self;
}

@end
