// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpClient.h"
#import <Foundation/Foundation.h>

@class MS_Reachability;

@interface MSHttpClient ()

@property(nonatomic) NSURLSession *session;
@property(nonatomic) MS_Reachability *reachability;
@property(nonatomic) NSMutableSet *pendingCalls;
@property(nonatomic) NSArray *retryIntervals;
@property(nonatomic) BOOL paused;
@property(nonatomic) BOOL enabled;
@property(nonatomic) NSURLSessionConfiguration *sessionConfiguration;
@end
