// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBaseOptions.h"

@interface MSWriteOptions : MSBaseOptions

/**
 * Initialize the Token result object.
 *
 * @param ttl timeToLive Device document time to live in seconds.
 *
 * @return A writeOptions instance.
 */
- (instancetype)initWithTtl:(NSInteger)ttl;

@end
