#import "MS_Reachability.h"
#import <Foundation/NSObject.h>

@interface MSMockReachability : NSObject

+ (void)setCurrentNetworkStatus:(NetworkStatus)networkStatus;

+ (id)startMocking;

@end
