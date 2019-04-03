// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDocumentWrapper.h"
#import "MSDataSourceError.h"
#import "MSDataStoreInternal.h"
#import "MSLoggerInternal.h"
#import "MSSerializableObject.h"

@implementation MSDocumentWrapper

@synthesize jsonValue = _jsonValue;
@synthesize deserializedValue = _deserializedValue;
@synthesize documentId = _documentId;
@synthesize partition = _partition;
@synthesize eTag = _eTag;
@synthesize lastUpdatedDate = _lastUpdatedDate;
@synthesize error = _error;

- (instancetype)initWithDeserializedValue:(id<MSSerializableDocument>)deserializedValue
                                partition:(NSString *)partition
                               documentId:(NSString *)documentId
                                     eTag:(NSString *)eTag
                          lastUpdatedDate:(NSDate *)lastUpdatedDate {
  if ((self = [super init])) {

    // Create json string.
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[deserializedValue serializeToDictionary] options:0 error:&error];
    if (error) {
      MSLogWarning([MSDataStore logTag], @"Failed to parse the deserializedValue, error : %@", error.localizedDescription);
    } else {
      _jsonValue = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    _deserializedValue = deserializedValue;
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
