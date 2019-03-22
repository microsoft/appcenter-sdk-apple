// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpClient.h"
#import <Foundation/Foundation.h>

@class MS_Reachability;

@interface MSHttpClient ()

@property NSURLSession *session;
@property MS_Reachability *reachability;
@property NSSet *pendingCalls;

@end
