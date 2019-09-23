// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAppCenterInternal.h"
#import "MSAuthTokenContextDelegateWrapper.h"

@class MSAuthTokenContextDelegate;

@implementation MSAuthTokenContextDelegateWrapper

@synthesize delegate = _delegate;
@synthesize authTokenCompletionHandler = _authTokenCompletionHandler;

- (instancetype)initWithAuthTokenDelegate:(id<MSAuthTokenDelegate>)authTokenDelegate
               authTokenCompletionHandler:(MSAuthTokenCompletionHandler)authTokenCompletionHandler {
  if ((self = [self init])) {
    _delegate = authTokenDelegate;
    _authTokenCompletionHandler = authTokenCompletionHandler;
  }
  return self;
}

- (void)authTokenContext:(__unused MSAuthTokenContext *)authTokenContext
    refreshAuthTokenForAccountId:(__unused NSString *_Nullable)accountId {
  [self.delegate appCenter:[MSAppCenter sharedInstance] acquireAuthTokenWithCompletionHandler:self.authTokenCompletionHandler];
}

@end
