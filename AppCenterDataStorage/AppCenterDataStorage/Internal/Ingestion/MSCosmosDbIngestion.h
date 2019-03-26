// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpIngestion.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Error domain for Storage.
 */
static NSString *const MSDataStorageErrorDomain = @"MSDataStorageErrorDomain";

@interface MSCosmosDbIngestion : MSHttpIngestion

/**
 * A flag that indicates offline mode is on or off.
 */
@property(nonatomic) BOOL offlineMode;

@end

NS_ASSUME_NONNULL_END
