// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDocumentWrapper.h"
#import "MSDataSourceError.h"
#import "MSDataStoreInternal.h"
#import "MSLogger.h"
#import "MSSerializableObject.h"
#import "MSServiceInternal.h"

@implementation MSDocumentWrapper

@synthesize jsonValue = _jsonValue;
@synthesize deserializedValue = _deserializedValue;
@synthesize documentId = _documentId;
@synthesize partition = _partition;
@synthesize eTag = _eTag;
@synthesize lastUpdatedDate = _lastUpdatedDate;
@synthesize error = _error;

- (instancetype)initWithDeserializedValue:(id<MSSerializableDocument>)deserializedValue
                                jsonValue:(NSString *)jsonValue
                                partition:(NSString *)partition
                               documentId:(NSString *)documentId
                                     eTag:(NSString *)eTag
                          lastUpdatedDate:(NSDate *)lastUpdatedDate {
  if ((self = [super init])) {
    _deserializedValue = deserializedValue;
    _jsonValue = jsonValue;
    _partition = partition;
    _documentId = documentId;
    _eTag = eTag;
    _lastUpdatedDate = lastUpdatedDate;
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
