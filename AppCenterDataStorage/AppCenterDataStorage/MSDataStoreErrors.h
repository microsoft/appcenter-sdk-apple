// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAppCenterErrors.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Domain

static NSString *const kMSACDataStoreErrorDomain = MS_APP_CENTER_BASE_DOMAIN @"DataStore.ErrorDomain";

#pragma mark - General

// CosmosDB (HTTP) error codes.
// Documentation: https://docs.microsoft.com/en-us/rest/api/cosmos-db/http-status-codes-for-cosmosdb
NS_ENUM(NSInteger){MSACDocumentUnknownErrorCode = 0,
                   MSACDocumentSucceededErrorCode = 200,
                   MSACDocumentCreatedErrorCode = 201,
                   MSACDocumentNoContentErrorCode = 204,
                   MSACDocumentBadRequestErrorCode = 400,
                   MSACDocumentUnauthorizedErrorCode = 401,
                   MSACDocumentForbiddenErrorCode = 403,
                   MSACDocumentNotFoundErrorCode = 404,
                   MSACDocumentRequestTimeoutErrorCode = 408,
                   MSACDocumentConflictErrorCode = 409,
                   MSACDocumentPreconditionFailedErrorCode = 412,
                   MSACDocumentEntityTooLargeErrorCode = 413,
                   MSACDocumentTooManyRequestsErrorCode = 429,
                   MSACDocumentRetryWithErrorCode = 449,
                   MSACDocumentInternalServerErrorErrorCode = 500,
                   MSACDocumentServiceUnavailableErrorCode = 503};

// Error codes.
// FIXME: Re-index these codes (we have our own domain so we can index at 0 and reserve ranges for us).
NS_ENUM(NSInteger){MSACDataStoreErrorJSONSerializationFailed = -620000, MSACDataStoreErrorHTTPError = -620001,
                   MSACDataStoreErrorLocalDocumentNotFound = -620002, MSACDataStoreErrorLocalDocumentExpired = -620003,
                   MSACDataStoreInvalidClassCode = -620004};

// Error descriptions.
static NSString const *kMSACDataStoreInvalidClassDesc =
    @"Provided class does not conform to serialization protocol (MSSerializableDocument).";

NS_ASSUME_NONNULL_END
