// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterErrors.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Domain

// Error documentation here: https://docs.microsoft.com/en-us/rest/api/cosmos-db/http-status-codes-for-cosmosdb
static NSString *const kMSACDataStoreErrorDomain = MS_APP_CENTER_BASE_DOMAIN @"DataStoreErrorDomain";

#pragma mark - Error Codes

NS_ENUM(NSInteger){kMSACDocumentUnknownErrorCode = 0,
                   kMSACDocumentSucceededErrorCode = 200,
                   kMSACDocumentCreatedErrorCode = 201,
                   kMSACDocumentNoContentErrorCode = 204,
                   kMSACDocumentBadRequestErrorCode = 400,
                   kMSACDocumentUnauthorizedErrorCode = 401,
                   kMSACDocumentForbiddenErrorCode = 403,
                   kMSACDocumentNotFoundErrorCode = 404,
                   kMSACDocumentRequestTimeoutErrorCode = 408,
                   kMSACDocumentConflictErrorCode = 409,
                   kMSACDocumentPreconditionFailedErrorCode = 412,
                   kMSACDocumentEntityTooLargeErrorCode = 413,
                   kMSACDocumentTooManyRequestErrorCode = 429,
                   kMSACDocumentRetryWithErrorCode = 449,
                   kMSACDocumentInternalServerErrorErrorCode = 500,
                   kMSACDocumentServiceUnavailableErrorCode = 503};

NS_ASSUME_NONNULL_END
