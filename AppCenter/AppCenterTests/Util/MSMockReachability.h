#import "MS_Reachability.h"

@interface MSMockReachability : NSObject

/**
 * A property indicating the current status of the network.
 */
@property(class) NetworkStatus currentNetworkStatus;

/**
 * Start to mock the MS_Reachability.
 */
+ (id)startMocking;

@end
