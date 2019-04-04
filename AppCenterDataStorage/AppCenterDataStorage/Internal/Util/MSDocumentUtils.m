// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDocumentUtils.h"
#import "MSDataSourceError.h"
#import "MSDataStorageConstants.h"
#import "MSDataStoreErrors.h"
#import "MSDataStoreInternal.h"
#import "MSDocumentWrapper.h"
#import "MSLogger.h"
#import "NSObject+MSDictionaryUtils.h"

/**
 * CosmosDb document identifier key.
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
 * CosmosDb document partition key key.
 */
static NSString *const kMSDocumentPartitionKey = @"PartitionKey";

/**
 * CosmosDb document key.
 */
static NSString *const kMSDocumentKey = @"document";

@implementation MSDocumentUtils

+ (NSDictionary *)documentPayloadWithDocumentId:(NSString *)documentId partition:(NSString *)partition document:(NSDictionary *)document {
  return @{kMSDocument : document, kMSPartitionKey : partition, kMSIdKey : documentId};
}

+ (MSDocumentWrapper *)documentWrapperFromData:(NSData *_Nullable)data documentType:(Class)documentType {

  // Deserialize data.
  NSError *error;
  NSObject *dictionary;
  if (data) {
    dictionary = [NSJSONSerialization JSONObjectWithData:(NSData *)data options:0 error:&error];
  }

  // Handle deserialization error.
  if (error || !dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
    if (!error) {
      error = [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                         code:MSACDataStoreErrorJSONSerializationFailed
                                     userInfo:@{NSLocalizedDescriptionKey : @"Can't deserialize JSON payload"}];
    }
    MSLogError([MSDataStore logTag], @"Error deserializing data: %@", [error description]);
    return [[MSDocumentWrapper alloc] initWithError:error documentId:nil];
  }

  // Proceed from the dictionary.
  return [MSDocumentUtils documentWrapperFromDictionary:(NSDictionary *)dictionary documentType:documentType];
};

+ (MSDocumentWrapper *)documentWrapperFromDictionary:(NSObject *)object documentType:(Class)documentType {

  // Extract CosmosDB metadata information (id, date, etag) and partition key.
  NSString *documentId;
  NSDate *lastUpdatedDate;
  NSString *etag;
  NSString *partition;
  if (![object isDictionaryWithKey:kMSDocumentIdKey keyType:[NSString class]] ||
      ![object isDictionaryWithKey:kMSDocumentTimestampKey keyType:[NSNumber class]] ||
      ![object isDictionaryWithKey:kMSDocumentEtagKey keyType:[NSString class]] ||
      ![object isDictionaryWithKey:kMSPartitionKey keyType:[NSString class]]) {

    // Prepare and return error.
    NSError *error = [[NSError alloc]
        initWithDomain:kMSACDataStoreErrorDomain
                  code:MSACDataStoreErrorJSONSerializationFailed
              userInfo:@{NSLocalizedDescriptionKey : @"Can't deserialize document (missing system properties or partition key)"}];
    MSLogError([MSDataStore logTag], @"Error deserializing data: %@", [error description]);
    return [[MSDocumentWrapper alloc] initWithError:error documentId:nil];
  }
  NSDictionary *dictionary = (NSDictionary *)object;
  documentId = dictionary[kMSDocumentIdKey];
  lastUpdatedDate = [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)dictionary[kMSDocumentTimestampKey] doubleValue]];
  etag = dictionary[kMSDocumentEtagKey];
  partition = dictionary[kMSPartitionKey];

  // Extract json value.
  NSString *jsonValue;
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
  if (!error) {
    jsonValue = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }

  // Deserialize document.
  id<MSSerializableDocument> deserializedValue;
  if (!error && ![dictionary isDictionaryWithKey:kMSDocumentKey keyType:[NSDictionary class]]) {
    error = [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                       code:MSACDataStoreErrorJSONSerializationFailed
                                   userInfo:@{NSLocalizedDescriptionKey : @"Can't deserialize document (missing document property)"}];
  }
  if (!error) {
    deserializedValue = [(id<MSSerializableDocument>)[documentType alloc] initFromDictionary:(NSDictionary *)dictionary[kMSDocumentKey]];
  }

  // Return document wrapper.
  MSDataSourceError *dataSourceError;
  if (error) {
    dataSourceError = [[MSDataSourceError alloc] initWithError:error];
    MSLogError([MSDataStore logTag], @"Error deserializing data: %@", [error description]);
  } else {
    MSLogDebug([MSDataStore logTag], @"Successfully deserialized document: %@ (partition: %@)", documentId, partition);
  }
  return [[MSDocumentWrapper alloc] initWithDeserializedValue:deserializedValue
                                                    jsonValue:jsonValue
                                                    partition:partition
                                                   documentId:documentId
                                                         eTag:etag
                                              lastUpdatedDate:lastUpdatedDate
                                                        error:dataSourceError];
}

@end
