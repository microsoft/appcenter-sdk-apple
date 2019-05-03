// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSData.h"
#import "MSDataErrorInternal.h"
#import "MSDataErrors.h"
#import "MSDataInternal.h"
#import "MSDocumentWrapperInternal.h"
#import "MSLoggerInternal.h"
#import "MSSerializableObject.h"

@implementation MSDocumentWrapper

- (instancetype)initWithDeserializedValue:(id<MSSerializableDocument>)deserializedValue
                                jsonValue:(NSString *)jsonValue
                                partition:(NSString *)partition
                               documentId:(NSString *)documentId
                                     eTag:(NSString *)eTag
                          lastUpdatedDate:(NSDate *)lastUpdatedDate
                         pendingOperation:(nullable NSString *)pendingOperation
                          fromDeviceCache:(BOOL)fromDeviceCache {
  return [self initWithDeserializedValue:deserializedValue
                               jsonValue:jsonValue
                               partition:partition
                              documentId:documentId
                                    eTag:eTag
                         lastUpdatedDate:lastUpdatedDate
                        pendingOperation:pendingOperation
                         fromDeviceCache:fromDeviceCache
                                   error:nil];
}

- (instancetype)initWithDeserializedValue:(id<MSSerializableDocument>)deserializedValue
                                jsonValue:(NSString *)jsonValue
                                partition:(NSString *)partition
                               documentId:(NSString *)documentId
                                     eTag:(NSString *)eTag
                          lastUpdatedDate:(NSDate *)lastUpdatedDate
                         pendingOperation:(nullable NSString *)pendingOperation
                          fromDeviceCache:(BOOL)fromDeviceCache
                                    error:(MSDataError *)error {
  if ((self = [super init])) {
    _deserializedValue = deserializedValue;
    _jsonValue = jsonValue;
    _partition = partition;
    _documentId = documentId;
    _eTag = eTag;
    _lastUpdatedDate = lastUpdatedDate;
    _error = error;
    _pendingOperation = pendingOperation;
    _fromDeviceCache = fromDeviceCache;
  }
  return self;
}

- (instancetype)initWithError:(MSDataError *)error documentId:(NSString *)documentId partition:(NSString *)partition {
  return [self initWithError:error documentId:documentId partition:partition eTag:nil];
}

- (instancetype)initWithError:(MSDataError *)error documentId:(NSString *)documentId partition:(NSString *)partition eTag:(NSString *)eTag {
  if ((self = [super init])) {
    _documentId = documentId;
    _error = error;
    _partition = partition;
    _eTag = eTag;
  }
  return self;
}

@end
