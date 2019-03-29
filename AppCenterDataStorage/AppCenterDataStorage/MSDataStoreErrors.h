// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterErrors.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSDataStoreErrors : NSObject

/*
 * Return an unexpected deserialization error object.
 */
+ (NSError *) unexpectedDeserializationError;

@end

#pragma mark - Domain

// Custom error domain constants.
static NSString *const kMSACDataStoreErrorDomain = MS_APP_CENTER_BASE_DOMAIN @"DataStoreErrorDomain";
static NSString *const kMSACDataStoreErrorDescriptionKey = @"MSDataStoreErrorDescriptionKey";

#pragma mark - Local error codes (within the domain)

// Error codes.
NS_ENUM(NSInteger){kMSACLocalDocumentUnexpectedDeserializationError = 1};
  
// Error descriptions.
static NSString const *kMSACLocalDocumentUnexpectedDeserializationErrorDesc = @"Unexpected deserialization error";

#pragma mark - CosmosDB error codes

// Error documentation here: https://docs.microsoft.com/en-us/rest/api/cosmos-db/http-status-codes-for-cosmosdb
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
                   kMSACDocumentTooManyRequestsErrorCode = 429,
                   kMSACDocumentRetryWithErrorCode = 449,
                   kMSACDocumentInternalServerErrorErrorCode = 500,
                   kMSACDocumentServiceUnavailableErrorCode = 503};

typedef NS_ENUM(NSInteger, MSIdentityErrorCode) { MSDataStoreErrorJSONSerializationFailed = -620000, MSDataStoreErrorHTTPError = -620001 };

NS_ASSUME_NONNULL_END
