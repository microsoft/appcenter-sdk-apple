// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDocumentWrapper.h"
#import "MSDataSourceError.h"
#import "MSDataStoreInternal.h"
#import "MSLogger.h"
#import "MSSerializableObject.h"
#import "MSServiceInternal.h"

/**
 * CosmosDb document id key.
 */
static NSString *const kMSDocumentIdKey = @"id";

/**
 * CosmosDb document timestamp key.
 */
static NSString *const kMSDocumentTimestampKey = @"_ts";

/**
 * CosmosDb document eTag key.
 */
static NSString *const kMSDocumentEtagKey = @"_etag";

/**
 * CosmosDb document key.
 */
static NSString *const kMSDocumentKey = @"document";

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
    _deserializedValue = deserializedValue;
    _partition = partition;
    _documentId = documentId;
    _eTag = eTag;
    _lastUpdatedDate = lastUpdatedDate;
  }
  return self;
}

- (instancetype)initWithData:(NSData *)data documentType:(Class)documentType partition:(NSString *)partition {
  if ((self = [super init])) {

    // Try to deserialize the data.
    NSError *deserializeError;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&deserializeError];

    // Handle logging.
    if (deserializeError) {
      MSLogError([MSDataStore logTag], @"Error deserializing data: %@", [deserializeError description]);
    }
    MSLogDebug([MSDataStore logTag], @"Deserializing document from data: %@", json);

    // Instanciate requested document type.
    id<MSSerializableDocument> deserializedDocument =
        [(id<MSSerializableDocument>)[documentType alloc] initFromDictionary:(NSDictionary *)json[kMSDocumentKey]];

    // Build document wrapper object.
    NSTimeInterval interval = [(NSString *)json[kMSDocumentTimestampKey] doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    NSString *eTag = json[kMSDocumentEtagKey];
    MSLogDebug([MSDataStore logTag], @"Document created: %@", data);
    return [self initWithDeserializedValue:deserializedDocument
                                 partition:partition
                                documentId:json[kMSDocumentIdKey]
                                      eTag:eTag
                           lastUpdatedDate:date];
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
