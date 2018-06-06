#import "MSOneCollectorChannelDelegate.h"

@class MSOneCollectorIngestion;

@protocol MSChannelUnitProtocol;
@protocol MSLog;

@class MSCSEpochAndSeq;

@interface MSOneCollectorChannelDelegate ()

/**
 * Collection of channel unit protocols per group Id.
 */
@property(nonatomic) NSMutableDictionary<NSString *, id<MSChannelUnitProtocol>> *oneCollectorChannels;

/**
 * Http sender to send logs to One Collector endpoint.
 */
@property(nonatomic) MSOneCollectorIngestion *oneCollectorSender;

/**
 * Keep track of epoch and sequence per tenant token.
 */
@property(nonatomic) NSMutableDictionary<NSString *, MSCSEpochAndSeq *> *epochsAndSeqsByIKey;

/**
 * UUID created on first-time SDK initialization.
 */
@property(nonatomic) NSUUID *installId;

/**
 * Returns 'YES' if the log should be sent to one collector.
 */
- (BOOL) shouldSendLogToOneCollector:(id<MSLog>)log;

@end
