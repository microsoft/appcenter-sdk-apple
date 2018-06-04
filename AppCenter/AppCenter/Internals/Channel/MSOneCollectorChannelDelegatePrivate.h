#import "MSOneCollectorChannelDelegate.h"

@class MSOneCollectorIngestion;

@protocol MSChannelUnitProtocol;

@interface MSOneCollectorChannelDelegate ()

@property(nonatomic) NSMutableDictionary<NSString *, id<MSChannelUnitProtocol>> *oneCollectorChannels;
@property(nonatomic) MSOneCollectorIngestion *oneCollectorSender;

@end
