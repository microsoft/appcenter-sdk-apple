#import "MSSessionHistoryInfo.h"

static NSString *const kMSSessionIdKey = @"sessionIdKey";

/**
 * This class is used to associate session id with the timestamp that it was created.
 */
@implementation MSSessionHistoryInfo

- (instancetype)initWithTimestamp:(NSDate *)timestamp andSessionId:(NSString *)sessionId {
  self = [super initWithTimestamp:timestamp];
  if (self) {
    _sessionId = sessionId;
  }
  return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _sessionId = [coder decodeObjectForKey:kMSSessionIdKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.sessionId forKey:kMSSessionIdKey];
}

@end
