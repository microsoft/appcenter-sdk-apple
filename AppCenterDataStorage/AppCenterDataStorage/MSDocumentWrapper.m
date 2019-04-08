// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDocumentWrapper.h"
#import "MSDataSourceError.h"
#import "MSDataStoreInternal.h"
#import "MSLoggerInternal.h"
#import "MSSerializableObject.h"

@implementation MSDocumentWrapper

@synthesize deserializedValue = _deserializedValue;
@synthesize jsonValue = _jsonValue;
@synthesize partition = _partition;
@synthesize documentId = _documentId;
@synthesize eTag = _eTag;
@synthesize lastUpdatedDate = _lastUpdatedDate;
@synthesize error = _error;

- (instancetype)initWithDeserializedValue:(id<MSSerializableDocument>)deserializedValue
                                jsonValue:(NSString *)jsonValue
                                partition:(NSString *)partition
                               documentId:(NSString *)documentId
                                     eTag:(NSString *)eTag
                          lastUpdatedDate:(NSDate *)lastUpdatedDate
                                    error:(MSDataSourceError *)error {
  if ((self = [super init])) {
    _deserializedValue = deserializedValue;
    _jsonValue = jsonValue;
    _partition = partition;
    _documentId = documentId;
    _eTag = eTag;
    _lastUpdatedDate = lastUpdatedDate;
    _error = error;
  }
  return self;
}

- (instancetype)initWithError:(NSError *)error documentId:(NSString *)documentId {
  if ((self = [super init])) {
    _documentId = documentId;
    _error = [[MSDataSourceError alloc] initWithError:error];
  }
  return self;
}

- (BOOL)fromDeviceCache {
  // @todo
  return false;
}

@end
