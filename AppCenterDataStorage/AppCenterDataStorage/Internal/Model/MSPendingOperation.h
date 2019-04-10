// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSPendingOperation : NSObject

/**
 * Pending operation.
 */
@property(nonatomic, strong) NSString *operation;

/**
 * Document partition.
 */
@property(nonatomic, strong) NSString *partition;

/**
 * Document Id.
 */
@property(nonatomic, strong) NSString *documentId;

/**
 * Document as string.
 */
@property(nonatomic, strong) NSString *document;

/**
 * Document etag.
 */
@property(nonatomic, strong) NSString *etag;

/**
 * Document epiration time.
 */
@property(nonatomic) NSTimeInterval expirationTime;

/**
 * Initialize pending operation object.
 *
 * @param operation Pending operation.
 * @param partition Document partition.
 * @param documentId Document Id.
 * @param document Document object as string.
 * @param etag Document etag.
 * @param expirationTime Document expiration time.
 * @return A pending operation instance.
 */
- (instancetype)initWithOperation:(NSString *)operation
                        partition:(NSString *)partition
                       documentId:(NSString *)documentId
                         document:(NSString *)document
                             etag:(NSString *)etag
                   expirationTime:(NSTimeInterval)expirationTime;

@end
