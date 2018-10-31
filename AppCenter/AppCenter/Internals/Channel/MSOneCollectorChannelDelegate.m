#import "MSAbstractLogInternal.h"
#import "MSAppCenterInternal.h"
#import "MSCSData.h"
#import "MSCSEpochAndSeq.h"
#import "MSCSExtensions.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSConstants+Internal.h"
#import "MSOneCollectorChannelDelegatePrivate.h"
#import "MSOneCollectorIngestion.h"
#import "MSSDKExtension.h"

static NSString *const kMSOneCollectorBaseUrl = @"https://mobile.events.data.microsoft.com"; // TODO: move to constants?
static NSString *const kMSBaseErrorMsg = @"Log validation failed.";

/**
 * Log name regex. alnum characters, no heading or trailing periods, no heading underscores, min length of 4, max length of 100.
 */
NSString *const kMSLogNameRegex = @"^[a-zA-Z0-9]((\\.(?!(\\.|$)))|[_a-zA-Z0-9]){3,99}$";

@implementation MSOneCollectorChannelDelegate

- (instancetype)init {
  self = [super init];
  if (self) {
    _oneCollectorChannels = [NSMutableDictionary new];
    _oneCollectorIngestion = [[MSOneCollectorIngestion alloc] initWithBaseUrl:kMSOneCollectorBaseUrl];
    _epochsAndSeqsByIKey = [NSMutableDictionary new];
  }
  return self;
}

- (instancetype)initWithInstallId:(NSUUID *)installId {
  self = [self init];
  if (self) {
    _installId = installId;
  }
  return self;
}

- (void)channelGroup:(id<MSChannelGroupProtocol>)channelGroup didAddChannelUnit:(id<MSChannelUnitProtocol>)channel {

  // Add OneCollector group based on the given channel's group id.
  NSString *groupId = channel.configuration.groupId;
  if (![self isOneCollectorGroup:groupId]) {
    NSString *oneCollectorGroupId = [NSString stringWithFormat:@"%@%@", channel.configuration.groupId, kMSOneCollectorGroupIdSuffix];
    MSChannelUnitConfiguration *channelUnitConfiguration =
        [[MSChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:oneCollectorGroupId];
    id<MSChannelUnitProtocol> channelUnit = [channelGroup addChannelUnitWithConfiguration:channelUnitConfiguration
                                                                            withIngestion:self.oneCollectorIngestion];
    self.oneCollectorChannels[groupId] = channelUnit;
  }
}

- (void)channel:(id<MSChannelProtocol>)__unused channel prepareLog:(id<MSLog>)log {

  // Prepare Common Schema logs.
  if ([log isKindOfClass:[MSCommonSchemaLog class]]) {
    MSCommonSchemaLog *csLog = (MSCommonSchemaLog *)log;

    // Set SDK extension values.
    MSCSEpochAndSeq *epochAndSeq = self.epochsAndSeqsByIKey[csLog.iKey];
    if (!epochAndSeq) {
      epochAndSeq = [[MSCSEpochAndSeq alloc] initWithEpoch:MS_UUID_STRING];
    }
    csLog.ext.sdkExt.epoch = epochAndSeq.epoch;
    csLog.ext.sdkExt.seq = ++epochAndSeq.seq;
    csLog.ext.sdkExt.installId = self.installId;
    self.epochsAndSeqsByIKey[csLog.iKey] = epochAndSeq;

    // Set install ID to SDK.
    csLog.ext.sdkExt.installId = self.installId;
  }
}

- (void)channel:(id<MSChannelProtocol>)channel
    didPrepareLog:(id<MSLog>)log
       internalId:(NSString *)__unused internalId
            flags:(MSFlags)flags {
  id<MSChannelUnitProtocol> channelUnit = (id<MSChannelUnitProtocol>)channel;
  id<MSChannelUnitProtocol> oneCollectorChannelUnit = nil;
  NSString *groupId = channelUnit.configuration.groupId;

  /*
   * Reroute Custom Schema logs to their One Collector channel if they were enqueued to a non One Collector channel. Happens to logs from
   * the log buffer after a crash.
   */
  if ([(NSObject *)log isKindOfClass:[MSCommonSchemaLog class]] && ![self isOneCollectorGroup:groupId]) {
    oneCollectorChannelUnit = self.oneCollectorChannels[groupId];
    if (oneCollectorChannelUnit) {
      [oneCollectorChannelUnit enqueueItem:log flags:flags];
    }
    return;
  }
  if (![self shouldSendLogToOneCollector:log] || ![channel conformsToProtocol:@protocol(MSChannelUnitProtocol)]) {
    return;
  }
  oneCollectorChannelUnit = self.oneCollectorChannels[groupId];
  if (!oneCollectorChannelUnit) {
    return;
  }
  id<MSLogConversion> logConversion = (id<MSLogConversion>)log;
  NSArray<MSCommonSchemaLog *> *commonSchemaLogs = [logConversion toCommonSchemaLogsWithFlags:flags];
  for (MSCommonSchemaLog *commonSchemaLog in commonSchemaLogs) {
    [oneCollectorChannelUnit enqueueItem:commonSchemaLog flags:flags];
  }
}

- (BOOL)channelUnit:(id<MSChannelUnitProtocol>)channelUnit shouldFilterLog:(id<MSLog>)log {

  // Validate Custom Schema logs, filter out invalid logs.
  if ([log isKindOfClass:[MSCommonSchemaLog class]]) {
    if (![self isOneCollectorGroup:channelUnit.configuration.groupId]) {
      return true;
    }
    return ![self validateLog:(MSCommonSchemaLog *)log];
  }

  // It's an App Center log. Filter out if it contains token(s) since it's already re-enqueued as CS log(s).
  return [[log transmissionTargetTokens] count] > 0;
}

- (void)channel:(id<MSChannelProtocol>)channel didSetEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deletedData {
  if ([channel conformsToProtocol:@protocol(MSChannelUnitProtocol)]) {
    NSString *groupId = ((id<MSChannelUnitProtocol>)channel).configuration.groupId;
    if (![self isOneCollectorGroup:groupId]) {

      // Mirror disabling state to OneCollector channels.
      [self.oneCollectorChannels[groupId] setEnabled:isEnabled andDeleteDataOnDisabled:deletedData];
    }
  } else if ([channel conformsToProtocol:@protocol(MSChannelGroupProtocol)] && !isEnabled && deletedData) {

    // Reset epoch and seq values when SDK is disabled as a whole.
    [self.epochsAndSeqsByIKey removeAllObjects];
  }
}

- (void)channel:(id<MSChannelProtocol>)channel didPauseWithIdentifyingObject:(id<NSObject>)identifyingObject {
  if ([channel conformsToProtocol:@protocol(MSChannelUnitProtocol)]) {
    NSString *groupId = ((id<MSChannelUnitProtocol>)channel).configuration.groupId;
    id<MSChannelUnitProtocol> oneCollectorChannel = self.oneCollectorChannels[groupId];
    [oneCollectorChannel pauseWithIdentifyingObject:identifyingObject];
  }
}

- (void)channel:(id<MSChannelProtocol>)channel didResumeWithIdentifyingObject:(id<NSObject>)identifyingObject {
  if ([channel conformsToProtocol:@protocol(MSChannelUnitProtocol)]) {
    NSString *groupId = ((id<MSChannelUnitProtocol>)channel).configuration.groupId;
    id<MSChannelUnitProtocol> oneCollectorChannel = self.oneCollectorChannels[groupId];
    [oneCollectorChannel resumeWithIdentifyingObject:identifyingObject];
  }
}

#pragma mark - Helper

- (BOOL)isOneCollectorGroup:(NSString *)groupId {
  return [groupId hasSuffix:kMSOneCollectorGroupIdSuffix];
}

- (BOOL)shouldSendLogToOneCollector:(id<MSLog>)log {
  NSObject *logObject = (NSObject *)log;
  return [[log transmissionTargetTokens] count] > 0 && [log conformsToProtocol:@protocol(MSLogConversion)] &&
         ![logObject isKindOfClass:[MSCommonSchemaLog class]];
}

- (BOOL)validateLog:(MSCommonSchemaLog *)log {
  if (![self validateLogName:log.name]) {
    return NO;
  }

  // Property values are valid strings already.
  return YES;
}

- (BOOL)validateLogName:(NSString *)name {

  // Name mustn't be nil.
  if (!name.length) {
    MSLogError([MSAppCenter logTag], @"%@ Name must not be nil or empty.", kMSBaseErrorMsg);
    return NO;
  }

  // The Common Schema event name must conform to a regex.
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:kMSLogNameRegex options:0 error:nil];
  NSRange range = NSMakeRange(0, name.length);
  NSUInteger count = [regex numberOfMatchesInString:name options:0 range:range];
  if (!count) {
    MSLogError([MSAppCenter logTag], @"%@ Name must match '%@' but was '%@'", kMSBaseErrorMsg, kMSLogNameRegex, name);
    return NO;
  }
  return YES;
}

@end
