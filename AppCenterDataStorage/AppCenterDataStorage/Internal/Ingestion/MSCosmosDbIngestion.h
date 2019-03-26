// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
#import "MSHttpIngestion.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Error domain for Storage.
 */
static NSString *const MSDataStorageErrorDomain = @"MSDataStorageErrorDomain";

@interface MSCosmosDbIngestion : MSHttpIngestion

@property BOOL offlineMode;

- (id)initWithOfflineMode:(BOOL)offlineMode;

@end

NS_ASSUME_NONNULL_END
