#import "MSOneCollectorChannelDelegate.h"

@protocol MSChannelUnitProtocol;

@interface MSOneCollectorChannelDelegate ()

@property(nonatomic) NSMutableDictionary<NSString *, id<MSChannelUnitProtocol>> *oneCollectorChannels;

@end
