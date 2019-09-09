// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSAuthTokenDelegate;

/**
 * Completion handler that returns the authentication token.
 */
typedef void (^MSAuthTokenCompletionHandler)(NSString *jwt);

@protocol MSAuthTokenDelegate <NSObject>

- (void)appCenter:(MSAppCenter *)appCenter
    acquireAuthTokenWithCompletionHandler:(MSAuthTokenCompletionHandler)completionHandler;

@end
