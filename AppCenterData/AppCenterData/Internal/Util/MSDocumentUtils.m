// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <objc/runtime.h>

#import "MSDataConstants.h"
#import "MSDataErrorInternal.h"
#import "MSDataErrors.h"
#import "MSDataInternal.h"
#import "MSDocumentUtils.h"
#import "MSDocumentWrapperInternal.h"
#import "MSLogger.h"
#import "MSUtility+Date.h"

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
                                     partition:(NSString *)partition
                                    documentId:(NSString *)documentId
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
      error = [[NSError alloc] initWithDomain:kMSACDataErrorDomain
                                         code:MSACDataErrorJSONSerializationFailed
                                     userInfo:@{NSLocalizedDescriptionKey : @"Can't deserialize JSON payload"}];
    }
    MSLogError([MSData logTag], @"Error deserializing data: %@", [error description]);
    MSDataError *dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorJSONSerializationFailed innerError:error message:nil];
    return [[MSDocumentWrapper alloc] initWithError:dataError partition:partition documentId:documentId];
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
      error = [[NSError alloc] initWithDomain:kMSACDataErrorDomain
                                         code:MSACDataErrorJSONSerializationFailed
                                     userInfo:@{NSLocalizedDescriptionKey : @"Can't deserialize JSON payload"}];
    }
    MSLogError([MSData logTag], @"Error deserializing data: %@", [error localizedDescription]);
    MSDataError *dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorJSONSerializationFailed innerError:error message:nil];
    return [[MSDocumentWrapper alloc] initWithError:dataError partition:partition documentId:documentId eTag:eTag];
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
      ![MSDocumentUtils isReferenceDictionaryWithKey:object key:kMSPartitionKey keyType:[NSString class]] ||
      ![MSDocumentUtils isReferenceDictionaryWithKey:object key:kMSDocumentKey keyType:[NSDictionary class]]) {

    // Prepare and return error.
    NSString *errorMessage = @"Can't deserialize document (missing system properties, partition key, or document)";
    MSDataError *dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorJSONSerializationFailed
                                                         innerError:nil
                                                            message:errorMessage];
    MSLogError([MSData logTag], @"Error deserializing data: %@.", [dataError localizedDescription]);
    return [[MSDocumentWrapper alloc] initWithError:dataError partition:nil documentId:nil];
  }
  NSDictionary *dictionary = (NSDictionary *)object;
  NSString *documentId = dictionary[kMSDocumentIdKey];
  NSDate *lastUpdatedDate = [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)dictionary[kMSDocumentTimestampKey] doubleValue]];
  NSString *eTag = dictionary[kMSDocumentEtagKey];
  NSString *partition = dictionary[kMSPartitionKey];
  return [self documentWrapperFromDictionary:(NSDictionary *)dictionary[kMSDocumentKey]
                                documentType:documentType
                                        eTag:eTag
                             lastUpdatedDate:lastUpdatedDate
                                   partition:partition
                                  documentId:documentId
                            pendingOperation:nil
                             fromDeviceCache:fromDeviceCache];
}

+ (MSDocumentWrapper *)documentWrapperFromDictionary:(NSDictionary *)dictionary
                                        documentType:(Class)documentType
                                                eTag:(NSString *)eTag
                                     lastUpdatedDate:(NSDate *)lastUpdatedDate
                                           partition:(NSString *)partition
                                          documentId:(NSString *)documentId
                                    pendingOperation:(nullable NSString *)pendingOperation
                                     fromDeviceCache:(BOOL)fromDeviceCache {
  MSDataError *dataError;
  id<MSSerializableDocument> deserializedValue;
  NSString *jsonValue = [self jsonValueForDictionary:dictionary dataError:&dataError];
  if (jsonValue) {

    // Deserialize document.
    deserializedValue = [(id<MSSerializableDocument>)[documentType alloc] initFromDictionary:dictionary];
    MSLogDebug([MSData logTag], @"Successfully deserialized document: %@ (partition: %@)", documentId, partition);
  }
  if (dataError) {
    return [[MSDocumentWrapper alloc] initWithError:dataError
                                          partition:partition
                                         documentId:documentId
                                               eTag:eTag
                                    lastUpdatedDate:lastUpdatedDate
                                   pendingOperation:pendingOperation
                                    fromDeviceCache:fromDeviceCache];
  } else {
    return [[MSDocumentWrapper alloc] initWithDeserializedValue:deserializedValue
                                                      jsonValue:jsonValue
                                                      partition:partition
                                                     documentId:documentId
                                                           eTag:eTag
                                                lastUpdatedDate:lastUpdatedDate
                                               pendingOperation:pendingOperation
                                                fromDeviceCache:fromDeviceCache];
  }
}

+ (NSString *)jsonValueForDictionary:(NSDictionary *)dictionary dataError:(MSDataError *__autoreleasing *)dataError {

  // Validate dictionary
  if (![NSJSONSerialization isValidJSONObject:dictionary]) {
    NSString *errorMessage = @"Dictionary contains values that cannot be processed as JSON.";
    NSError *jsonError = [[NSError alloc] initWithDomain:kMSACDataErrorDomain
                                                    code:MSACDataErrorJSONSerializationFailed
                                                userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
    *dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorJSONSerializationFailed innerError:jsonError message:errorMessage];
    MSLogError([MSData logTag], errorMessage);
    return nil;
  }

  // Serialize dictionary intermediate to JSON string.
  NSError *serializationError;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&serializationError];
  if (serializationError) {
    NSString *errorMessage = @"Document could not be serialized.";
    *dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorJSONSerializationFailed
                                             innerError:serializationError
                                                message:errorMessage];
    MSLogError([MSData logTag], errorMessage);
    return nil;
  }
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
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

+ (NSString *)outgoingOperationIdWithPartition:(NSString *)partition documentId:(NSString *)documentId {
  return [NSString stringWithFormat:@"%@_%@", partition, documentId];
}

@end
