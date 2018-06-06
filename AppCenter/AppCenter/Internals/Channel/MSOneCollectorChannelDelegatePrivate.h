#import "MSOneCollectorChannelDelegate.h"

@protocol MSChannelUnitProtocol;
@protocol MSLog;

@class MSCSEpochAndSeq;

@interface MSOneCollectorChannelDelegate ()

/**
 * Collection of channel unit protocols per group Id.
 */
@property(nonatomic) NSMutableDictionary<NSString *, id<MSChannelUnitProtocol>> *oneCollectorChannels;

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
