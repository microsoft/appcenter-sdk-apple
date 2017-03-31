#import "MSEventLog.h"

static NSString *const kMSTypeEvent = @"event";

static NSString *const kMSId = @"id";
static NSString *const kMSName = @"name";

@implementation MSEventLog

@synthesize type = _type;

- (instancetype)init {
  if ((self = [super init])) {
    _type = kMSTypeEvent;
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
  if (!object || ![super isEqual:object] || ![object isKindOfClass:[MSEventLog class]]) {
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
    _type = [coder decodeObjectForKey:kMSType];
    _eventId = [coder decodeObjectForKey:kMSId];
    _name = [coder decodeObjectForKey:kMSName];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kMSType];
  [coder encodeObject:self.eventId forKey:kMSId];
  [coder encodeObject:self.name forKey:kMSName];
}

@end
