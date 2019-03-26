// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSCosmosDbIngestion.h"
#import "MSDataStore.h"
#import "MSServiceInternal.h"
#import "MSStorageIngestion.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDataStore <T : id <MSSerializableDocument>>() <MSServiceInternal>

/**
 * An token exchange url that is used to get resouce tokens.
 */
@property(nonatomic, copy) NSString *tokenExchangeUrl;

/**
 * An ingestion instance that is used to send a request for new token exchange service.
 */
@property(nonatomic, nullable) MSStorageIngestion *ingestion;

/**
 * An ingestion instance that is used to send a request to CosmosDb.
 */
@property(nonatomic, nullable) MSCosmosDbIngestion *cosmosHttpClient;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
