// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSPendingOperation : NSObject

/**
 * Pending operation.
 */
@property(nonatomic, copy) NSString *operation;

/**
 * Document partition.
 */
@property(nonatomic, copy) NSString *partition;

/**
 * Document Id.
 */
@property(nonatomic, copy) NSString *documentId;

/**
 * Document as dictionary.
 */
@property(nonatomic, copy) NSDictionary *document;

/**
 * Document etag.
 */
@property(nonatomic, copy) NSString *etag;

/**
 * Document expiration time.
 */
@property(nonatomic) NSTimeInterval expirationTime;

/**
 * Initialize pending operation object.
 *
 * @param operation Pending operation.
 * @param partition Document partition.
 * @param documentId Document Id.
 * @param document Document object as dictionary.
 * @param etag Document etag.
 * @param expirationTime Document expiration time.
 *
 * @return A pending operation instance.
 */
- (instancetype)initWithOperation:(NSString *)operation
                        partition:(NSString *)partition
                       documentId:(NSString *)documentId
                         document:(NSDictionary *)document
                             etag:(NSString *)etag
                   expirationTime:(NSTimeInterval)expirationTime;

/**
 * Indicate if time is expired.
 *
 * @param time Time to be checked.
 *
 * @return YES is time is expired.
 */
+ (BOOL)isExpiredWithExpirationTime:(NSInteger)time;

@end
