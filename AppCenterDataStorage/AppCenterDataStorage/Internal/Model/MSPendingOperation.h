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
 * Document as dictionary.
 */
@property(nonatomic, strong) NSDictionary *document;

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
 * Get Time to live time of the operation.
 *
 * @return Time to live of the operaiotn.
 */
- (NSInteger)deviceTimeToLiveFromOperation;

/**
 * Indicate if time is expired.
 *
 * @param time Time to be checked.
 *
 * @return YES is time is expired.
 */
+ (BOOL)isExpiredWithExpirationTime:(NSInteger)time;

@end
