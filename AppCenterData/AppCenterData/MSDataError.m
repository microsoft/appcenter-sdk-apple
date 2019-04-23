// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataError.h"
#import "MSConstants.h"
#import "MSDataConstants.h"
#import "MSDataErrors.h"

@implementation MSDataError

@synthesize error = _error;
@synthesize errorCode = _errorCode;

- (instancetype)initWithError:(NSError *)error {
  if ((self = [super init])) {
    _error = error;
    _errorCode = [MSDataError errorCodeFromError:error];
  }
  return self;
}

+ (NSInteger)errorCodeFromError:(NSError *)error {

  // Try to extract the error from the user info dictionary.
  if (error.userInfo[kMSCosmosDbHttpCodeKey]) {
    return [(NSNumber *)error.userInfo[kMSCosmosDbHttpCodeKey] integerValue];
  }

  // Return default unknown error code.
  return MSHTTPCodesNo0XXInvalidUnknown;
}

@end
