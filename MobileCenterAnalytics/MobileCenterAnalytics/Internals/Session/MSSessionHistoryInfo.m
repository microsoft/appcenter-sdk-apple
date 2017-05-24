#import "MSSessionHistoryInfo.h"

static NSString *const kMSSessionIdKey = @"sessionIdKey";
static NSString *const kMSToffsetKey = @"toffsetKey";

/**
 * This class is used to associate session id with the timestamp that it was created.
 */
@implementation MSSessionHistoryInfo

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _sessionId = [coder decodeObjectForKey:kMSSessionIdKey];
    _toffset = [coder decodeObjectForKey:kMSToffsetKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.sessionId forKey:kMSSessionIdKey];
  [coder encodeObject:self.toffset forKey:kMSToffsetKey];
}

- (instancetype)initWithTOffset:(NSNumber *)toffset andSessionId:(NSString *)sessionId {
  self = [super init];
  if (self) {
    _sessionId = sessionId;
    _toffset = toffset;
  }
  return self;
}

@end
