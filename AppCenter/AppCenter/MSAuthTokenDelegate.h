// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSAppCenter;

typedef void (^MSAuthTokenCompletionHandler)(NSString *jwt);

@protocol MSAuthTokenDelegate <NSObject>

/**
 * Acquire the auth token and then execute the completion handler.
 *
 * @param appCenter The AppCenter instance from which the method is called.
 * @param completionHandler The code to be executed upon acquiring the token.
 */
- (void)appCenter:(MSAppCenter *)appCenter acquireAuthTokenWithCompletionHandler:(MSAuthTokenCompletionHandler)completionHandler;

@end
