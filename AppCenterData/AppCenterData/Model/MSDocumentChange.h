// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSDocumentChange : NSObject

/**
 * Document id.
 */
@property(nonatomic, copy, readonly) NSString *documentId;

/**
 * Document partition.
 */
@property(nonatomic, copy, readonly) NSString *partition;

/**
 * Document change operation type.
 */
@property(nonatomic, copy, readonly) NSString *operation;

/**
 * Document change timestamp.
 */
@property(nonatomic, readonly) NSInteger timestamp;

/**
 * Initialize an object from dictionary.
 *
 * @param dictionary A dictionary that contains key/value paris for a document change.
 *
 * @return A new instance.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
