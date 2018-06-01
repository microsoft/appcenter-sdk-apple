#import "MSChannelProtocol.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSCommonSchemaLog.h"
#import "MSLog.h"
#import "MSOneCollectorChannelDelegatePrivate.h"

static NSString *const kMSOneCollectorGroupIdSuffix = @"/one";

@implementation MSOneCollectorChannelDelegate

- (id)init {
  self = [super init];
  if (self) {
    _oneCollectorChannels = [NSMutableDictionary new];
  }

  return self;
}

- (void)channelGroup:(id<MSChannelGroupProtocol>)channelGroup didAddChannelUnit:(id<MSChannelUnitProtocol>)channel {

  // Add OneCollector group based on the given channel's group id.
  NSString *groupId = channel.configuration.groupId;
  if (![self isOneCollectorGroup:groupId]) {
    NSString *oneCollectorGroupId =
        [NSString stringWithFormat:@"%@%@", channel.configuration.groupId, kMSOneCollectorGroupIdSuffix];
    MSChannelUnitConfiguration *channelUnitConfiguration =
        [[MSChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:oneCollectorGroupId];

    // TODO need to figure out actual sender for One Collector
    id<MSChannelUnitProtocol> channelUnit =
        [channelGroup addChannelUnitWithConfiguration:channelUnitConfiguration withSender:nil];
    self.oneCollectorChannels[groupId] = channelUnit;
  }
}

- (BOOL)channelUnit:(id<MSChannelUnitProtocol>)channelUnit shouldFilterLog:(id<MSLog>)log {

  // Do not filter the log from one collector channels.
  if ([self isOneCollectorGroup:channelUnit.configuration.groupId]) {
    return NO;
  }
  return [[log transmissionTargetTokens] count] > 0;
}

- (void)channel:(id<MSChannelProtocol>)channel
              didSetEnabled:(BOOL)isEnabled
    andDeleteDataOnDisabled:(BOOL)deletedData {
  if ([channel conformsToProtocol:@protocol(MSChannelUnitProtocol)]) {
    NSString *groupId = ((id<MSChannelUnitProtocol>)channel).configuration.groupId;
    if (![self isOneCollectorGroup:groupId]) {
      [self.oneCollectorChannels[groupId] setEnabled:isEnabled andDeleteDataOnDisabled:deletedData];
    }
  }
}

- (void)channel:(id<MSChannelProtocol>)channel didPrepareLog:(id<MSLog>)log withInternalId:(NSString *)__unused internalId {
  if (![self shouldSendLogToOneCollector:log] ||
      ![channel conformsToProtocol:@protocol(MSChannelUnitProtocol)]) {
    return;
  }
  id<MSChannelUnitProtocol> channelUnit = (id<MSChannelUnitProtocol>)channel;
  NSString *groupId = channelUnit.configuration.groupId;
  id<MSChannelUnitProtocol> oneCollectorChannelUnit = [self.oneCollectorChannels objectForKey:groupId];
  if (!oneCollectorChannelUnit) {
    return;
  }

  // TODO: do the actual conversion
  MSCommonSchemaLog *commonSchemaLog = [MSCommonSchemaLog new];
  [commonSchemaLog setType:[log type]];
  [commonSchemaLog setTimestamp:[log timestamp]];
  [commonSchemaLog setDevice:[log device]];
  [oneCollectorChannelUnit enqueueItem:commonSchemaLog];
}

- (BOOL)isOneCollectorGroup:(NSString *)groupId {
  return [groupId hasSuffix:kMSOneCollectorGroupIdSuffix];
}

- (BOOL)shouldSendLogToOneCollector:(id<MSLog>)log {
  NSObject *logObject = (NSObject *)log;
  return [[log transmissionTargetTokens] count] > 0 && ![logObject isKindOfClass:[MSCommonSchemaLog class]];
}

@end
