// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
#import "MSDataStoreErrors.h"

@implementation MSDataStoreErrors

+ (NSError *) unexpectedDeserializationError {
  return [[NSError alloc]
          initWithDomain:kMSACDataStoreErrorDomain
          code:kMSACLocalDocumentUnexpectedDeserializationError
          userInfo:@{kMSACDataStoreErrorDescriptionKey : kMSACLocalDocumentUnexpectedDeserializationErrorDesc}];
}

@end
