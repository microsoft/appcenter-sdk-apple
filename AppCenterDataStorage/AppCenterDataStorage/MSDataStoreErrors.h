// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAppCenterErrors.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Domain

static NSString *const kMSACDataStoreErrorDomain = MS_APP_CENTER_BASE_DOMAIN @"DataStore.ErrorDomain";

#pragma mark - General

// Error codes.
// FIXME: Re-index these codes (we have our own domain so we can index at 0 and reserve ranges for us).
NS_ENUM(NSInteger){MSACDataStoreErrorJSONSerializationFailed = -620000,
                   MSACDataStoreErrorHTTPError = -620001,
                   MSACDataStoreErrorDocumentNotFound = -620002,
                   MSACDataStoreErrorLocalDocumentExpired = -620003,
                   MSACDataStoreNotAuthenticated = -620004,
                   MSACDataStoreInvalidClassCode = -620005,
                   MSACDataStoreDontCache = -620006,
                   MSACDataStoreLocalStoreError = -620007,
                   MSACDataStoreDocumentIdError = -620008,
                   MSACDataStoreInvalidPartitionError = -620009,
                   MSACDataStoreInvalidTokenExchangeResponse = -620010,
                   MSACDataStoreUnableToGetTokenError = -620011};

// Error descriptions.
static NSString const *kMSACDataStoreInvalidClassDesc =
    @"Provided class does not conform to serialization protocol (MSSerializableDocument).";
static NSString const *kMSACDataStoreCosmosDbErrorResponseDesc = @"Unexpected error while talking to CosmosDB.";
static NSString const *kMSACDocumentCreationDesc = @"Can't create document.";

NS_ASSUME_NONNULL_END
