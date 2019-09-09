// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContextDelegate.h"
#import "MSAuthTokenDelegate.h"

@interface MSAuthTokenContextDelegateWrapper : NSObject <MSAuthTokenContextDelegate>

@property id<MSAuthTokenDelegate> delegate;

@property MSAuthTokenCompletionHandler authTokenCompletionHandler;

- (instancetype)initWithAuthTokenDelegate:(id<MSAuthTokenDelegate>)authTokenDelegate authTokenCompletionHandler:(MSAuthTokenCompletionHandler)authTokenCompletionHandler;

@end
