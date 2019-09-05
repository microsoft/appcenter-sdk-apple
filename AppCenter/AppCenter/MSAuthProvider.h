// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

@interface MSAuthProvider : NSObject

typedef void(^MSAuthProviderCompletionBlock)(NSString *jwt);

- (void)authenticationProvider:(MSAuthProvider *)authProvider
                                acquireTokenWithCompletionHandler:(MSAuthProviderCompletionBlock)completionHandler;

@end
