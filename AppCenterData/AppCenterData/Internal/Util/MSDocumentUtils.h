// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSDocumentWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDocumentUtils : NSObject

/**
 * Create document payload.
 *
 * @param documentId Document Id.
 * @param partition CosmosDb partition.
 * @param document Document in dictionary format.
 *
 * @return Dictionary of document payload.
 */
+ (NSDictionary *)documentPayloadWithDocumentId:(NSString *)documentId partition:(NSString *)partition document:(NSDictionary *)document;

/**
 * Deserialize a CosmosDB document from data and return a document wrapper (valid or in an error state).
 *
 * @param data Data from which to create the document wrapper.
 * @param documentType The type of document to instantiate.
 * @param partition The partition of the document.
 * @param documentId The DocumentId.
 * @param fromDeviceCache Flag indicating if the document wrapper was retrieved remotely or not.
 *
 * @return Document wrapper (valid or in an error state).
 */
+ (MSDocumentWrapper *)documentWrapperFromData:(nullable NSData *)data
                                  documentType:(Class)documentType
                                     partition:(NSString *)partition
                                    documentId:(NSString *)documentId
                               fromDeviceCache:(BOOL)fromDeviceCache;

/**
 * Deserialize a CosmosDB document from a dictionary and return a document wrapper (valid or in an error state).
 *
 * @param object Dictionary (expected) from which to create the document wrapper.
 * @param documentType The type of document to instantiate.
 * @param fromDeviceCache Flag indicating if the document wrapper was retrieved remotely or not.
 *
 * @return Document wrapper (valid or in an error state).
 */
+ (MSDocumentWrapper *)documentWrapperFromDictionary:(NSObject *)object
                                        documentType:(Class)documentType
                                     fromDeviceCache:(BOOL)fromDeviceCache;

/**
 * Deserialize a document from a byte array representing a JSON object.
 *
 * @param data Data from which to create the document wrapper.
 * @param documentType The type of document to instantiate.
 * @param eTag The eTag for the document.
 * @param lastUpdatedDate The last time the document was updated.
 * @param partition The partition of the document.
 * @param documentId The DocumentId.
 * @param pendingOperation The pending operation, or nil.
 * @param fromDeviceCache Flag indicating if the document wrapper was retrieved remotely or not.
 *
 * @return Document wrapper (valid or in an error state).
 */
+ (MSDocumentWrapper *)documentWrapperFromDocumentData:(nullable NSData *)data
                                          documentType:(Class)documentType
                                                  eTag:(NSString *)eTag
                                       lastUpdatedDate:(NSDate *)lastUpdatedDate
                                             partition:(NSString *)partition
                                            documentId:(NSString *)documentId
                                      pendingOperation:(nullable NSString *)pendingOperation
                                       fromDeviceCache:(BOOL)fromDeviceCache;

/**
 * Deserialize a document dictionary that contains no metadata.
 *
 * @param dictionary Dictionary from which to create the document wrapper.
 * @param documentType The type of document to instantiate.
 * @param eTag The eTag for the document.
 * @param lastUpdatedDate The last time the document was updated.
 * @param partition The partition of the document.
 * @param documentId The DocumentId.
 * @param pendingOperation The pending operation, or nil.
 * @param fromDeviceCache Flag indicating if the document wrapper was retrieved remotely or not.
 *
 * @return Document wrapper (valid or in an error state).
 */
+ (MSDocumentWrapper *)documentWrapperFromDictionary:(NSDictionary *)dictionary
                                        documentType:(Class)documentType
                                                eTag:(NSString *)eTag
                                     lastUpdatedDate:(NSDate *)lastUpdatedDate
                                           partition:(NSString *)partition
                                          documentId:(NSString *)documentId
                                    pendingOperation:(nullable NSString *)pendingOperation
                                     fromDeviceCache:(BOOL)fromDeviceCache;
/**
 * Check if a given class type implements the `MSSerializableDocument` protocol.
 *
 * @param classType The type to check.
 *
 * @return YES if the class type implements `MSSerializableDocument`; NO otherwise.
 */
+ (BOOL)isSerializableDocument:(Class)classType;

/**
 * Test if a reference is a dictionary that has a key of a given type.
 *
 * @param reference The reference to test.
 * @param key The key to look for in the dictionary reference.
 * @param keyType The expected key type.
 *
 * @return YES if the reference is a dictionary with a key of the given type; NO otherwise.
 */
+ (BOOL)isReferenceDictionaryWithKey:(nullable id)reference key:(NSString *)key keyType:(Class)keyType;

/**
 * Get operation id by combination of partition key and document Id.
 *
 * @param partition Partition key.
 * @param documentId Document Id.
 *
 * @return Operation Id.
 */
+ (NSString *)outgoingOperationIdWithPartition:(NSString *)partition documentId:(NSString *)documentId;

@end

NS_ASSUME_NONNULL_END
