#import "MSOneCollectorChannelDelegate.h"

@protocol MSChannelUnitProtocol;
@protocol MSLog;

@interface MSOneCollectorChannelDelegate ()

@property(nonatomic) NSMutableDictionary<NSString *, id<MSChannelUnitProtocol>> *oneCollectorChannels;

- (BOOL) shouldSendLogToOneCollector:(id<MSLog>)log;

- (NSString *) correspondingOneCollectorChannelGroupId:(id<MSChannelUnitProtocol>)channelUnit;

@end
