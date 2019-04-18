// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataSourceError.h"
#import "MSDataStorageConstants.h"
#import "MSDataStoreErrors.h"

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
  // Try to extract the error from the user info dictionary.
  if (error.userInfo[kMSCosmosDbHttpCodeKey]) {
    return [(NSNumber *)error.userInfo[kMSCosmosDbHttpCodeKey] integerValue];
  }
  
  // Return default unknown error code.
  return MSACDocumentUnknownErrorCode;
}

@end
