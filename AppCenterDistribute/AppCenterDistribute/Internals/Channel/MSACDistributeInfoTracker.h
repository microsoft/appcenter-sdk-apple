// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "AppCenter+Internal.h"

@interface MSACDistributeInfoTracker : NSObject <MSACChannelDelegate>

/**
 * Distribution group ID that is added to logs (if exists).
 */
@property(nonatomic, copy) NSString *distributionGroupId;

/**
 * Update the distribution group ID value that is added to logs.
 *
 * @param distributionGroupId The distribution group ID value that is added to logs.
 */
- (void)updateDistributionGroupId:(NSString *)distributionGroupId;

/**
 * Don't add the distribution group ID value to logs.
 */
- (void)removeDistributionGroupId;

@end
