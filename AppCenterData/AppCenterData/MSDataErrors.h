// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAppCenterErrors.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Domain

static NSString *const kMSACDataErrorDomain = MS_APP_CENTER_BASE_DOMAIN @"Data.ErrorDomain";

#pragma mark - General

// Error codes.
// FIXME: Re-index these codes (we have our own domain so we can index at 0 and reserve ranges for us).
NS_ENUM(NSInteger){MSACDataErrorJSONSerializationFailed = -620000,
                   MSACDataErrorHTTPError = -620001,
                   MSACDataErrorDocumentNotFound = -620002,
                   MSACDataErrorLocalDocumentExpired = -620003,
                   MSACDataNotAuthenticated = -620004,
                   MSACDataInvalidClassCode = -620005,
                   MSACDataDontCache = -620006,
                   MSACDataLocalStoreError = -620007,
                   MSACDataDocumentIdError = -620008,
                   MSACDataInvalidPartitionError = -620009,
                   MSACDataInvalidTokenExchangeResponse = -620010,
                   MSACDataUnableToGetTokenError = -620011};

// Error descriptions.
static NSString const *kMSACDataInvalidClassDesc =
    @"Provided class does not conform to serialization protocol (MSSerializableDocument).";
static NSString const *kMSACDataCosmosDbErrorResponseDesc = @"Unexpected error while talking to CosmosDB.";
static NSString const *kMSACDocumentCreationDesc = @"Can't create document.";

NS_ASSUME_NONNULL_END
