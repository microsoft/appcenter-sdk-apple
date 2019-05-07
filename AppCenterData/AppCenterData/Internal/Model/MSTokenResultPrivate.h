// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSTokenResult.h"

static NSString *const kMSDbName = @"dbName";
static NSString *const kMSStatus = @"status";
static NSString *const kMSPartition = @"partition";
static NSString *const kMSDbAccount = @"dbAccount";
static NSString *const kMSDbCollectionName = @"dbCollectionName";
static NSString *const kMSExpiresOn = @"expiresOn";
static NSString *const kMSToken = @"token";
static NSString *const kMSAccountId = @"accountId";

@interface MSTokenResult ()

/**
 * Convert a token object into a dictionary.
 *
 * @return The dictionary object.
 */
- (NSDictionary *)convertToDictionary;

@end
