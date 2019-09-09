// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
@class MSAppCenter;

/**
 * Completion handler that returns the authentication token.
 */
typedef void (^MSAuthTokenCompletionHandler)(NSString *jwt);

@protocol MSAuthTokenDelegate <NSObject>
@optional

- (void)appCenter:(MSAppCenter *)appCenter
    acquireAuthTokenWithCompletionHandler:(MSAuthTokenCompletionHandler)completionHandler;

@end
