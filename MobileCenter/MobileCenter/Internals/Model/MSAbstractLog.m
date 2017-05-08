#import "MSAbstractLogInternal.h"
#import "MSDevice.h"
#import "MSDeviceInternal.h"
#import "MSLogger.h"
#import "MSUtility+Date.h"

static NSString *const kMSSid = @"sid";
static NSString *const kMSToffset = @"toffset";
static NSString *const kMSDevice = @"device";
static NSString *const kMSType = @"type";

@implementation MSAbstractLog

@synthesize type = _type;
@synthesize toffset = _toffset;
@synthesize sid = _sid;
@synthesize device = _device;

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.type) {
    dict[kMSType] = self.type;
  }
  if (self.toffset) {

    // Set the toffset relative to current time. The toffset needs to be up to date.
    long long now = (long long)[MSUtility nowInMilliseconds];
    long long relativeTime = now - [self.toffset longLongValue];
    dict[kMSToffset] = @(relativeTime);
  }
  if (self.sid) {
    dict[kMSSid] = self.sid;
  }
  if (self.device) {
    dict[kMSDevice] = [self.device serializeToDictionary];
  }
  return dict;
}

- (BOOL)isValid {
  return self.type && self.toffset && self.device && [self.device isValid];
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSAbstractLog class]]) {
    return NO;
  }
  MSAbstractLog *log = (MSAbstractLog *)object;
  return ((!self.type && !log.type) || [self.type isEqualToString:log.type]) &&
         ((!self.toffset && !log.toffset) || [self.toffset isEqualToNumber:log.toffset]) &&
         ((!self.sid && !log.sid) || [self.sid isEqualToString:log.sid]) &&
         ((!self.device && !log.device) || [self.device isEqual:log.device]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _type = [coder decodeObjectForKey:kMSType];
    _toffset = [coder decodeObjectForKey:kMSToffset];
    _sid = [coder decodeObjectForKey:kMSSid];
    _device = [coder decodeObjectForKey:kMSDevice];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.type forKey:kMSType];
  [coder encodeObject:self.toffset forKey:kMSToffset];
  [coder encodeObject:self.sid forKey:kMSSid];
  [coder encodeObject:self.device forKey:kMSDevice];
}

@end
