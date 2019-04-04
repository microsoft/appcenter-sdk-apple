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
 * Test if a reference is a dictionary that has a key of a given type.
 *
 * @param reference The reference to test.
 * @param key The key to look for in the dictionary reference.
 * @param keyType The expected key type.
 */
+ (BOOL)isReferenceDictionaryWithKey:(id _Nullable)reference key:(NSString *)key keyType:(Class)keyType;

/**
 * Deserialize a CosmosDB document from data and return a document wrapper (valid or in an error state).
 *
 * @param data Data from which to create the document wrapper.
 * @param documentType The type of document to instantiate.
 */
+ (MSDocumentWrapper *)documentWrapperFromData:(NSData *_Nullable)data documentType:(Class)documentType;

/**
 * Deserialize a CosmosDB document from a dictionary and return a document wrapper (valid or in an error state).
 *
 * @param object Dictionary (expected) from which to create the document wrapper.
 * @param documentType The type of document to instantiate.
 */
+ (MSDocumentWrapper *)documentWrapperFromDictionary:(NSObject *)object documentType:(Class)documentType;

@end

NS_ASSUME_NONNULL_END
