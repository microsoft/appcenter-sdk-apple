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
  if ((self = [super init])) {
    _deserializedValue = deserializedValue;
    _jsonValue = jsonValue;
    _partition = partition;
    _documentId = documentId;
    _eTag = eTag;
    _lastUpdatedDate = lastUpdatedDate;
    _pendingOperation = pendingOperation;
    _fromDeviceCache = fromDeviceCache;
  }
  return self;
}

- (instancetype)initWithError:(MSDataError *)error partition:(NSString *)partition documentId:(NSString *)documentId {
  return [self initWithError:error partition:partition documentId:documentId eTag:nil];
}

- (instancetype)initWithError:(MSDataError *)error partition:(NSString *)partition documentId:(NSString *)documentId eTag:(NSString *)eTag {
  return [self initWithError:error
                   partition:partition
                  documentId:documentId
                        eTag:eTag
             lastUpdatedDate:nil
            pendingOperation:nil
             fromDeviceCache:NO];
}

- (instancetype)initWithError:(MSDataError *)error
                    partition:(NSString *)partition
                   documentId:(NSString *)documentId
                         eTag:(NSString *)eTag
              lastUpdatedDate:(NSDate *)lastUpdatedDate
             pendingOperation:(NSString *)pendingOperation
              fromDeviceCache:(BOOL)fromDeviceCache {
  if ((self = [super init])) {
    _documentId = documentId;
    _error = error;
    _partition = partition;
    _eTag = eTag;
    _lastUpdatedDate = lastUpdatedDate;
    _pendingOperation = pendingOperation;
    _fromDeviceCache = fromDeviceCache;
  }
  return self;
}

@end
