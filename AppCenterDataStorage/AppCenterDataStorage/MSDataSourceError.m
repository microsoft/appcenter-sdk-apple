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
  return [self initWithError:error errorCode:[MSDataSourceError errorCodeFromError:error]];
}

- (instancetype)initWithError:(NSError *)error errorCode:(NSInteger)errorCode {
  if ((self = [super init])) {
    _error = error;
    _errorCode = errorCode;
  }
  return self;
}

+ (NSInteger)errorCodeFromError:(NSError *)error {
  if (!error) {
    return kMSACDocumentSucceededErrorCode;
  }

  // Get error code form userInfo dictionary.
  NSDictionary *userInfo = (NSDictionary *)[error userInfo];
  if (userInfo[kMSCosmosDbHttpCodeKey]) {
    return [(NSNumber *)userInfo[kMSCosmosDbHttpCodeKey] integerValue];
  }
  return kMSACDocumentUnknownErrorCode;
}

@end
