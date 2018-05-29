#import "MSEventLog.h"
#import "AppCenter+Internal.h"

static NSString *const kMSTypeEvent = @"event";

static NSString *const kMSId = @"id";

@implementation MSEventLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSTypeEvent;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.eventId) {
    dict[kMSId] = self.eventId;
  }
  return dict;
}

- (BOOL)isValid {
  return [super isValid] && self.eventId;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSEventLog class]] || ![super isEqual:object]) {
    return NO;
  }
  MSEventLog *eventLog = (MSEventLog *)object;
  return ((!self.eventId && !eventLog.eventId) || [self.eventId isEqualToString:eventLog.eventId]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _eventId = [coder decodeObjectForKey:kMSId];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.eventId forKey:kMSId];
}

@end
