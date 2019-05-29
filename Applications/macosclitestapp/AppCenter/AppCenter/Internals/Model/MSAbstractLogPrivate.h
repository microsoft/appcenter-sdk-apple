// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

static NSString *const kMSDevice = @"device";
static NSString *const kMSDistributionGroupId = @"distributionGroupId";
static NSString *const kMSSId = @"sid";
static NSString *const kMSType = @"type";
static NSString *const kMSTimestamp = @"timestamp";
static NSString *const kMSUserId = @"userId";

@interface MSAbstractLog ()

/**
 * List of transmission target tokens that this log should be sent to.
 */
@property(nonatomic) NSSet *transmissionTargetTokens;

@end
