#import "MSOneCollectorChannelDelegate.h"

@protocol MSChannelUnitProtocol;

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

@end
