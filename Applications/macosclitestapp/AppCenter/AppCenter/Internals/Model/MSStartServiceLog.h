// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSNoAutoAssignSessionIdLog.h"

@interface MSStartServiceLog : MSAbstractLog <MSNoAutoAssignSessionIdLog>

/**
 * Services which started with SDK
 */
@property(nonatomic) NSArray<NSString *> *services;

@end
