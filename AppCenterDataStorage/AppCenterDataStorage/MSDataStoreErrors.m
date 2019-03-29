// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataStoreErrors.h"
#import <Foundation/Foundation.h>

@implementation MSDataStoreErrors

+ (NSError *)unexpectedDeserializationError {
  return [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                    code:kMSACLocalDocumentUnexpectedDeserializationError
                                userInfo:@{kMSACDataStoreErrorDescriptionKey : kMSACLocalDocumentUnexpectedDeserializationErrorDesc}];
}

@end
