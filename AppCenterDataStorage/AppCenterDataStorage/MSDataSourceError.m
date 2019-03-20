// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataSourceError.h"
#import "MSDataStoreErrors.h"

/**
 * CosmosDb Http code key.
 */
static NSString *const kMSCosmosDbHttpCodeKey = @"com.Microsoft.AppCenter.HttpCodeKey";

@implementation MSDataSourceError

@synthesize error = _error;
@synthesize errorCode = _errorCode;

- (instancetype)initWithError:(NSError *)error {
  return [self initWithError:error errorCode:[MSDataSourceError errorCodeWithError:error]];
}
- (instancetype)initWithError:(NSError *)error errorCode:(NSInteger)errorCode {
  if ((self = [super init])) {
    _error = error;
    _errorCode = errorCode;
  }
  return self;
}

+ (NSInteger)errorCodeWithError:(NSError *)error {
  if (error == nil) {
    return kMSACDocumentSucceededErrorCode;
  }

  // Get error code.
  NSNumber *errorCode = [error userInfo][kMSCosmosDbHttpCodeKey];
  switch ([errorCode integerValue]) {
  case 200:
    return kMSACDocumentSucceededErrorCode;
  case 201:
    return kMSACDocumentCreatedErrorCode;
  case 204:
    return kMSACDocumentNoContentErrorCode;
  case 400:
    return kMSACDocumentBadRequestErrorCode;
  case 401:
    return kMSACDocumentUnauthorizedErrorCode;
  case 403:
    return kMSACDocumentForbiddenErrorCode;
  case 404:
    return kMSACDocumentNotFoundErrorCode;
  case 408:
    return kMSACDocumentRequestTimeoutErrorCode;
  case 409:
    return kMSACDocumentConflictErrorCode;
  case 412:
    return kMSACDocumentPreconditionFailedErrorCode;
  case 413:
    return kMSACDocumentEntityTooLargeErrorCode;
  case 429:
    return kMSACDocumentTooManyRequestErrorCode;
  case 449:
    return kMSACDocumentRetryWithErrorCode;
  case 500:
    return kMSACDocumentInternalServerErrorErrorCode;
  case 503:
    return kMSACDocumentServiceUnavailableErrorCode;
  default:
    return kMSACDocumentUnknownErrorCode;
  }
}

@end
