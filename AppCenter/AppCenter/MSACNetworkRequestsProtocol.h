// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef MSACNetworkRequestsProtocol_h
#define MSACNetworkRequestsProtocol_h

#import <Foundation/Foundation.h>

/**
 * Protocol to define an instance that can have network requests allowed/disallowed.
 */
NS_SWIFT_NAME(NetworkRequestsProtocol)
@protocol MSACNetworkRequestsProtocol <NSObject>

@required

/**
 * Allow or disallow network requests.
 */
- (void)setNetworkRequestsAllowed:(BOOL)isAllowed;

@end

#endif /* MSACNetworkRequestsProtocol_h */
