#import "MSEventLog.h"
#import "AppCenter+Internal.h"

static NSString *const kMSTypeEvent = @"event";

static NSString *const kMSId = @"id";
static NSString *const kMSName = @"name";

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
  if (self.name) {
    dict[kMSName] = self.name;
  }
  return dict;
}

- (BOOL)isValid {
  return [super isValid] && self.eventId && self.name;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSEventLog class]] || ![super isEqual:object]) {
    return NO;
  }
  MSEventLog *eventLog = (MSEventLog *)object;
  return ((!self.eventId && !eventLog.eventId) || [self.eventId isEqualToString:eventLog.eventId]) &&
         ((!self.name && !eventLog.name) || [self.name isEqualToString:eventLog.name]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _eventId = [coder decodeObjectForKey:kMSId];
    _name = [coder decodeObjectForKey:kMSName];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.eventId forKey:kMSId];
  [coder encodeObject:self.name forKey:kMSName];
}

@end
