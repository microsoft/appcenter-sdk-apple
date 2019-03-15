// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

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
