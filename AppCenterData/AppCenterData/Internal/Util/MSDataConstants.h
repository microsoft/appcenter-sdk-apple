// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

/**
 * Common constants.
 */
static NSString *const kMSDocument = @"document";
static NSString *const kMSPartitionKey = @"PartitionKey";
static NSString *const kMSIdKey = @"id";
static NSString *const kMSTokenResultSucceed = @"Succeed";

/**
 * Pending operation state names.
 */
static NSString *const kMSPendingOperationCreate = @"CREATE";
static NSString *const kMSPendingOperationReplace = @"REPLACE";
static NSString *const kMSPendingOperationDelete = @"DELETE";
static NSString *const kMSPendingOperationRead = nil;

/**
 * CosmosDB HTTP code key.
 */
static NSString *const kMSCosmosDbHttpCodeKey = @"MSHttpCodeKey";
