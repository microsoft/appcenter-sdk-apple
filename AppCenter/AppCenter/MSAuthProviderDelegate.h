// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSAuthProvider;

/**
 * Completion handler that returns the authentication token.
 */
typedef void (^MSAuthProviderCompletionBlock)(NSString *jwt);

@protocol MSAuthProviderDelegate <NSObject>

- (void)authProvider:(MSAuthProvider *)authProvider acquireTokenWithCompletionHandler:(MSAuthProviderCompletionBlock)completionHandler;

@end
