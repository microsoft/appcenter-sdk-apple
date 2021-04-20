// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef MSACNetworkRequests_h
#define MSACNetworkRequests_h

#import <Foundation/Foundation.h>

/**
 * Protocol to define an instance that can have network requests allowed/disallowed.
 */
NS_SWIFT_NAME(NetworkRequests)
@protocol MSACNetworkRequests <NSObject>

@required

/**
 * Allow or disallow network requests.
 */
- (void)setNetworkRequestsAllowed:(BOOL)isAllowed;

@end


#endif /* MSACNetworkRequests_h */
