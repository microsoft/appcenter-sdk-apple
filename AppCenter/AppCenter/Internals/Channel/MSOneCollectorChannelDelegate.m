#import "MSChannelProtocol.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
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

- (BOOL)shouldFilterLog:(id<MSLog>)log {
  return [self shouldSendLogToOneCollector:log];
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

  // TODO Maybe this should not be triggered by a channel group.
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

  //TODO Convert the log.
  id<MSLog> convertedLog;
  [oneCollectorChannelUnit enqueueItem:convertedLog];
}

- (BOOL)isOneCollectorGroup:(NSString *)groupId {
  return [groupId hasSuffix:kMSOneCollectorGroupIdSuffix];
}

// TODO This must return NO if the log is already a common schema log to avoid infinite recursion.
- (BOOL) shouldSendLogToOneCollector:(id<MSLog>)log {
  return [[log transmissionTargetTokens] count] > 0;
}

@end
