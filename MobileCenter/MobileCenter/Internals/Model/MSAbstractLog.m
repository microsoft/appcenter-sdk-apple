#import "MSAbstractLogInternal.h"
#import "MSDevice.h"
#import "MSLogger.h"
#import "MSDeviceInternal.h"
#import "MSUtility+Date.h"

static NSString *const kMSSid = @"sid";
static NSString *const kMSTimestamp = @"timestamp";
static NSString *const kMSDevice = @"device";
static NSString *const kMSType = @"type";

@implementation MSAbstractLog

@synthesize type = _type;
@synthesize timestamp = _timestamp;
@synthesize sid = _sid;
@synthesize device = _device;

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.type) {
    dict[kMSType] = self.type;
  }
  if (self.timestamp) {
    dict[kMSTimestamp] = [MSUtility dateToISO8601:self.timestamp];
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
  return self.type && self.timestamp && self.device && [self.device isValid];
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSAbstractLog class]]) {
    return NO;
  }
  MSAbstractLog *log = (MSAbstractLog *)object;
  return ((!self.type && !log.type) || [self.type isEqualToString:log.type]) &&
         ((!self.timestamp && !log.timestamp) || [self.timestamp isEqualToDate:log.timestamp]) &&
         ((!self.sid && !log.sid) || [self.sid isEqualToString:log.sid]) &&
         ((!self.device && !log.device) || [self.device isEqual:log.device]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _type = [coder decodeObjectForKey:kMSType];
    _timestamp = [coder decodeObjectForKey:kMSTimestamp];
    _sid = [coder decodeObjectForKey:kMSSid];
    _device = [coder decodeObjectForKey:kMSDevice];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.type forKey:kMSType];
  [coder encodeObject:self.timestamp forKey:kMSTimestamp];
  [coder encodeObject:self.sid forKey:kMSSid];
  [coder encodeObject:self.device forKey:kMSDevice];
}

#pragma mark - Utility

- (NSString *)serializeLogWithPrettyPrinting:(BOOL)prettyPrint {
  NSString *jsonString;
  NSJSONWritingOptions printOptions = prettyPrint ? NSJSONWritingPrettyPrinted : (NSJSONWritingOptions)0;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self serializeToDictionary] options:printOptions error:nil];

  if (jsonData) {
    jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
  }
  return jsonString;
}

@end
