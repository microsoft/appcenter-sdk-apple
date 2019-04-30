// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAppCenterErrors.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Domain

static NSString *const kMSACDataErrorDomain = MS_APP_CENTER_BASE_DOMAIN @"Data.ErrorDomain";

#pragma mark - General

// Error codes.
NS_ENUM(NSInteger){// System framework errors.
                   MSACDataInvalidClassCode = 101, MSACDataErrorJSONSerializationFailed = 102,

                   // Document errors.
                   MSACDataErrorDocumentNotFound = 200, MSACDataLocalStoreError = 201, MSACDataErrorLocalDocumentExpired = 202,
                   MSACDataDocumentIdError = 203, MSACDataInvalidPartitionError = 204, MSACDataInvalidTokenExchangeResponse = 205,

                   // Network errors
                   MSACDataErrorHTTPError = 300, MSACDataUnableToGetTokenError = 301};

// Error descriptions.
static NSString const *kMSACDataInvalidClassDesc = @"Provided class does not conform to serialization protocol (MSSerializableDocument).";
static NSString const *kMSACDataCosmosDbErrorResponseDesc = @"Unexpected error while talking to CosmosDB.";
static NSString const *kMSACDocumentCreationDesc = @"Can't create document.";

NS_ASSUME_NONNULL_END
