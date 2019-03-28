// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpIngestion.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSCosmosDbIngestion : MSHttpIngestion

/**
 * A flag that indicates offline mode is on or off.
 */
@property(atomic) BOOL offlineMode;

@end

NS_ASSUME_NONNULL_END
