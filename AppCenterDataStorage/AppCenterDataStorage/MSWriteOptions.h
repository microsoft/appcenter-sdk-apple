// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBaseOptions.h"

@interface MSWriteOptions : MSBaseOptions

/**
 * Initialize the MSWriteOptions object.
 *
 * @return A writeOptions instance.
 */
- (instancetype) initWithTimeToLive:(NSInteger)timeToLive;

@end
