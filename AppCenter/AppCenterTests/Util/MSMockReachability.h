#import "MS_Reachability.h"
#import <Foundation/NSObject.h>

@interface MSMockReachability : NSObject

/**
 * Set current network status for mock MS_Reachability.
 */
+ (void)setCurrentNetworkStatus:(NetworkStatus)networkStatus;

/**
 * Start to mock the MS_Reachability.
 */
+ (id)startMocking;

@end
