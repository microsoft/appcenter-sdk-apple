#import "MSACModelConstants.h"
#import "MSAbstractLogInternal.h"
#import "MSAbstractLogPrivate.h"
#import "MSAppExtension.h"
#import "MSCSExtensions.h"
#import "MSCSModelConstants.h"
#import "MSConstants+Internal.h"
#import "MSDevice.h"
#import "MSDeviceExtension.h"
#import "MSDeviceInternal.h"
#import "MSLocExtension.h"
#import "MSNetExtension.h"
#import "MSOSExtension.h"
#import "MSProtocolExtension.h"
#import "MSSDKExtension.h"
#import "MSUserExtension.h"
#import "MSUserIdContext.h"
#import "MSUtility+Date.h"
#import "MSUtility+StringFormatting.h"

/**
 * App namespace prefix for common schema.
 */
static NSString *const kMSAppNamespacePrefix = @"I";

@implementation MSAbstractLog

@synthesize type = _type;
@synthesize timestamp = _timestamp;
@synthesize sid = _sid;
@synthesize distributionGroupId = _distributionGroupId;
@synthesize userId = _userId;
@synthesize device = _device;
@synthesize tag = _tag;

- (instancetype)init {
  self = [super init];
  if (self) {
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.type) {
    dict[kMSType] = self.type;
  }
  if (self.timestamp) {
    dict[kMSTimestamp] = [MSUtility dateToISO8601:self.timestamp];
  }
  if (self.sid) {
    dict[kMSSId] = self.sid;
  }
  if (self.distributionGroupId) {
    dict[kMSDistributionGroupId] = self.distributionGroupId;
  }
  if (self.userId) {
    dict[kMSUserId] = self.userId;
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
  if (![(NSObject *)object isKindOfClass:[MSAbstractLog class]]) {
    return NO;
  }
  MSAbstractLog *log = (MSAbstractLog *)object;
  return ((!self.tag && !log.tag) || [self.tag isEqual:log.tag]) && ((!self.type && !log.type) || [self.type isEqualToString:log.type]) &&
         ((!self.timestamp && !log.timestamp) || [self.timestamp isEqualToDate:log.timestamp]) &&
         ((!self.sid && !log.sid) || [self.sid isEqualToString:log.sid]) &&
         ((!self.distributionGroupId && !log.distributionGroupId) || [self.distributionGroupId isEqualToString:log.distributionGroupId]) &&
         ((!self.userId && !log.userId) || [self.userId isEqualToString:log.userId]) &&
         ((!self.device && !log.device) || [self.device isEqual:log.device]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _type = [coder decodeObjectForKey:kMSType];
    _timestamp = [coder decodeObjectForKey:kMSTimestamp];
    _sid = [coder decodeObjectForKey:kMSSId];
    _distributionGroupId = [coder decodeObjectForKey:kMSDistributionGroupId];
    _userId = [coder decodeObjectForKey:kMSUserId];
    _device = [coder decodeObjectForKey:kMSDevice];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.type forKey:kMSType];
  [coder encodeObject:self.timestamp forKey:kMSTimestamp];
  [coder encodeObject:self.sid forKey:kMSSId];
  [coder encodeObject:self.distributionGroupId forKey:kMSDistributionGroupId];
  [coder encodeObject:self.userId forKey:kMSUserId];
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

#pragma mark - Transmission Target logic

- (NSSet *)transmissionTargetTokens {
  @synchronized(self) {
    return _transmissionTargetTokens;
  }
}

- (void)addTransmissionTargetToken:(NSString *)token {
  @synchronized(self) {
    if (self.transmissionTargetTokens == nil) {
      self.transmissionTargetTokens = [NSSet new];
    }
    NSMutableSet *mutableSet = [self.transmissionTargetTokens mutableCopy];
    [mutableSet addObject:token];
    self.transmissionTargetTokens = mutableSet;
  }
}

#pragma mark - MSLogConversion

- (NSArray<MSCommonSchemaLog *> *)toCommonSchemaLogsWithFlags:(MSFlags)flags {
  NSMutableArray<MSCommonSchemaLog *> *csLogs = [NSMutableArray new];
  for (NSString *token in self.transmissionTargetTokens) {
    MSCommonSchemaLog *csLog = [self toCommonSchemaLogForTargetToken:token flags:(MSFlags)flags];
    if (csLog) {
      [csLogs addObject:csLog];
    }
  }

  // Return nil if none are converted.
  return (csLogs.count > 0) ? csLogs : nil;
}

#pragma mark - Helper

- (MSCommonSchemaLog *)toCommonSchemaLogForTargetToken:(NSString *)token flags:(MSFlags)flags {
  MSCommonSchemaLog *csLog = [MSCommonSchemaLog new];
  csLog.transmissionTargetTokens = [NSSet setWithObject:token];
  csLog.ver = kMSCSVerValue;
  csLog.timestamp = self.timestamp;

  // TODO popSample not supported at this time.

  // Calculate iKey based on the target token.
  csLog.iKey = [MSUtility iKeyFromTargetToken:token];
  csLog.flags = flags;

  // TODO cV not supported at this time.

  // Setup extensions.
  csLog.ext = [MSCSExtensions new];

  // Protocol extension.
  csLog.ext.protocolExt = [MSProtocolExtension new];
  csLog.ext.protocolExt.devMake = self.device.oemName;
  csLog.ext.protocolExt.devModel = self.device.model;

  // User extension.
  csLog.ext.userExt = [MSUserExtension new];
  csLog.ext.userExt.localId = [MSUserIdContext prefixedUserIdFromUserId:self.userId];

  // FIXME Country code can be wrong if the locale doesn't correspond to the region in the setting (i.e.:fr_US). Convert user local to use
  // dash (-) as the separator as described in RFC 4646.  E.g., zh-Hans-CN.
  csLog.ext.userExt.locale = [self.device.locale stringByReplacingOccurrencesOfString:@"_" withString:@"-"];

  // OS extension.
  csLog.ext.osExt = [MSOSExtension new];
  csLog.ext.osExt.name = self.device.osName;
  csLog.ext.osExt.ver = [self combineOsVersion:self.device.osVersion withBuild:self.device.osBuild];

  // App extension.
  csLog.ext.appExt = [MSAppExtension new];
  csLog.ext.appExt.appId =
      [NSString stringWithFormat:@"%@%@%@", kMSAppNamespacePrefix, kMSCommonSchemaPrefixSeparator, self.device.appNamespace];
  csLog.ext.appExt.ver = self.device.appVersion;
  csLog.ext.appExt.locale = [[[NSBundle mainBundle] preferredLocalizations] firstObject];

  // Network extension.
  csLog.ext.netExt = [MSNetExtension new];
  csLog.ext.netExt.provider = self.device.carrierName;

  // SDK extension.
  csLog.ext.sdkExt = [MSSDKExtension new];
  csLog.ext.sdkExt.libVer = [self combineSDKLibVer:self.device.sdkName withVersion:self.device.sdkVersion];

  // Loc extension.
  csLog.ext.locExt = [MSLocExtension new];
  csLog.ext.locExt.tz = [self convertTimeZoneOffsetToISO8601:[self.device.timeZoneOffset integerValue]];

  // Device extension.
  csLog.ext.deviceExt = [MSDeviceExtension new];

  return csLog;
}

- (NSString *)combineOsVersion:(NSString *)version withBuild:(NSString *)build {
  NSString *combinedVersionAndBuild;
  if (version && version.length) {
    combinedVersionAndBuild = [NSString stringWithFormat:@"Version %@", version];
  }
  if (build && build.length) {
    combinedVersionAndBuild = [NSString stringWithFormat:@"%@ (Build %@)", combinedVersionAndBuild, build];
  }
  return combinedVersionAndBuild;
}

- (NSString *)combineSDKLibVer:(NSString *)name withVersion:(NSString *)version {
  NSString *combinedVersion;
  if (name && name.length && version && version.length) {
    combinedVersion = [NSString stringWithFormat:@"%@-%@", name, version];
  }
  return combinedVersion;
}

- (NSString *)convertTimeZoneOffsetToISO8601:(NSInteger)timeZoneOffset {
  NSInteger offsetInHour = timeZoneOffset / 60;
  NSInteger remainingMinutes = labs(timeZoneOffset) % 60;

  // This will look like this: +hhh:mm.
  return [NSString stringWithFormat:@"%+03ld:%02ld", (long)offsetInHour, (long)remainingMinutes];
}

@end
