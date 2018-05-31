#import "MSOneCollectorChannelDelegate.h"

@protocol MSChannelUnitProtocol;

@class MSCSEpochAndSeq;

@interface MSOneCollectorChannelDelegate ()

// TODO comment
@property(nonatomic) NSMutableDictionary<NSString *, id<MSChannelUnitProtocol>> *oneCollectorChannels;
@property(nonatomic) NSMutableDictionary<NSString *, MSCSEpochAndSeq *> *epochsAndSeqsByIKey;
@property(nonatomic) NSUUID *installId;

@end
