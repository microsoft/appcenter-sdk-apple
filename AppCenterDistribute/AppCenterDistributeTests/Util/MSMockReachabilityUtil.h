#import "MS_Reachability.h"
#import <Foundation/NSObject.h>

@interface MSMockReachabilityUtil : NSObject

@property(nonatomic) NetworkStatus currentNetworkStatus;

- (void)mockMSReachability;

@end
