// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <objc/runtime.h>

#import "MSDataSourceError.h"
#import "MSDataStorageConstants.h"
#import "MSDataStoreErrors.h"
#import "MSDataStoreInternal.h"
#import "MSDocumentUtils.h"
#import "MSDocumentWrapperInternal.h"
#import "MSLogger.h"

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

#pragma mark Interface

+ (NSDictionary *)documentPayloadWithDocumentId:(NSString *)documentId partition:(NSString *)partition document:(NSDictionary *)document {
  return @{kMSDocument : document, kMSPartitionKey : partition, kMSIdKey : documentId};
}

+ (MSDocumentWrapper *)documentWrapperFromData:(nullable NSData *)data
                                  documentType:(Class)documentType
                               fromDeviceCache:(BOOL)fromDeviceCache {

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
  return [MSDocumentUtils documentWrapperFromDictionary:(NSDictionary *)dictionary
                                           documentType:documentType
                                        fromDeviceCache:fromDeviceCache];
}

+ (MSDocumentWrapper *)documentWrapperFromDocumentData:(nullable NSData *)data
                                          documentType:(Class)documentType
                                                  eTag:(NSString *)eTag
                                       lastUpdatedDate:(NSDate *)lastUpdatedDate
                                             partition:(NSString *)partition
                                            documentId:(NSString *)documentId
                                      pendingOperation:(nullable NSString *)pendingOperation
                                       fromDeviceCache:(BOOL)fromDeviceCache {
  // Deserialize data.
  NSError *error;
  NSObject *dictionary;
  if (data) {
    dictionary = [NSJSONSerialization JSONObjectWithData:(NSData *)data options:0 error:&error];
  }

  // Handle deserialization error.
  if (error || ![dictionary isKindOfClass:[NSDictionary class]]) {
    if (!error) {
      error = [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                         code:MSACDataStoreErrorJSONSerializationFailed
                                     userInfo:@{NSLocalizedDescriptionKey : @"Can't deserialize JSON payload"}];
    }
    MSLogError([MSDataStore logTag], @"Error deserializing data: %@", [error localizedDescription]);
    return [[MSDocumentWrapper alloc] initWithError:error documentId:documentId];
  }

  // Proceed from the dictionary.
  return [self documentWrapperFromDictionary:(NSDictionary *)dictionary
                                documentType:documentType
                                        eTag:eTag
                             lastUpdatedDate:lastUpdatedDate
                                   partition:partition
                                  documentId:documentId
                            pendingOperation:pendingOperation
                             fromDeviceCache:fromDeviceCache];
}

+ (MSDocumentWrapper *)documentWrapperFromDictionary:(NSObject *)object
                                        documentType:(Class)documentType
                                     fromDeviceCache:(BOOL)fromDeviceCache {

  // Extract CosmosDB metadata information (id, date, etag) and partition key.
  if (![MSDocumentUtils isReferenceDictionaryWithKey:object key:kMSDocumentIdKey keyType:[NSString class]] ||
      ![MSDocumentUtils isReferenceDictionaryWithKey:object key:kMSDocumentTimestampKey keyType:[NSNumber class]] ||
      ![MSDocumentUtils isReferenceDictionaryWithKey:object key:kMSDocumentEtagKey keyType:[NSString class]] ||
      ![MSDocumentUtils isReferenceDictionaryWithKey:object key:kMSPartitionKey keyType:[NSString class]]) {

    // Prepare and return error.
    NSError *error = [[NSError alloc]
        initWithDomain:kMSACDataStoreErrorDomain
                  code:MSACDataStoreErrorJSONSerializationFailed
              userInfo:@{NSLocalizedDescriptionKey : @"Can't deserialize document (missing system properties or partition key)"}];
    MSLogError([MSDataStore logTag], @"Error deserializing data: %@", [error localizedDescription]);
    return [[MSDocumentWrapper alloc] initWithError:error documentId:nil];
  }
  NSDictionary *dictionary = (NSDictionary *)object;
  NSString *documentId = dictionary[kMSDocumentIdKey];
  NSDate *lastUpdatedDate = [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)dictionary[kMSDocumentTimestampKey] doubleValue]];
  NSString *eTag = dictionary[kMSDocumentEtagKey];
  NSString *partition = dictionary[kMSPartitionKey];
  return [self documentWrapperFromDictionary:dictionary
                                documentType:documentType
                                        eTag:eTag
                             lastUpdatedDate:lastUpdatedDate
                                   partition:partition
                                  documentId:documentId
                            pendingOperation:nil
                             fromDeviceCache:fromDeviceCache];
}

+ (BOOL)isSerializableDocument:(Class)classType {
  return class_conformsToProtocol(classType, @protocol(MSSerializableDocument));
}

+ (BOOL)isReferenceDictionaryWithKey:(nullable id)reference key:(NSString *)key keyType:(Class)keyType {

  // Validate the reference is a dictionary.
  if (!reference || ![(NSObject *)reference isKindOfClass:[NSDictionary class]]) {
    return NO;
  }

  // Validate the reference has the expected key.
  NSObject *keyObject = [(NSDictionary *)reference objectForKey:key];
  if (!keyObject) {
    return NO;
  }

  // Validate the key object is of the expected type.
  return [keyObject isKindOfClass:keyType];
}

#pragma mark Private

+ (MSDocumentWrapper *)documentWrapperFromDictionary:(NSDictionary *)dictionary
                                        documentType:(Class)documentType
                                                eTag:(NSString *)eTag
                                     lastUpdatedDate:(NSDate *)lastUpdatedDate
                                           partition:(NSString *)partition
                                          documentId:(NSString *)documentId
                                    pendingOperation:(nullable NSString *)pendingOperation
                                     fromDeviceCache:(BOOL)fromDeviceCache {

  // Extract json value.
  NSString *jsonValue;
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
  if (!error) {
    jsonValue = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }

  // Deserialize document.
  id<MSSerializableDocument> deserializedValue;
  if (!error && ![MSDocumentUtils isReferenceDictionaryWithKey:dictionary key:kMSDocumentKey keyType:[NSDictionary class]]) {
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
    MSLogError([MSDataStore logTag], @"Error deserializing data: %@", [error localizedDescription]);
  } else {
    MSLogDebug([MSDataStore logTag], @"Successfully deserialized document: %@ (partition: %@)", documentId, partition);
  }
  return [[MSDocumentWrapper alloc] initWithDeserializedValue:deserializedValue
                                                    jsonValue:jsonValue
                                                    partition:partition
                                                   documentId:documentId
                                                         eTag:eTag
                                              lastUpdatedDate:lastUpdatedDate
                                             pendingOperation:pendingOperation
                                                        error:dataSourceError
                                              fromDeviceCache:fromDeviceCache];
}

@end
