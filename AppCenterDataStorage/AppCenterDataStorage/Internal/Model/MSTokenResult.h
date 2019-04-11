// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSTokenResult : NSObject

/**
 * Partition.
 */
@property(nonatomic, readonly, copy) NSString *partition;

/**
 * Database account.
 */
@property(nonatomic, readonly, copy) NSString *dbAccount;

/**
 * Database name.
 */
@property(nonatomic, readonly, copy) NSString *dbName;

/**
 * Database collection Name.
 */
@property(nonatomic, readonly, copy) NSString *dbCollectionName;

/**
 * Database access token.
 */
@property(nonatomic, readonly, copy) NSString *token;

/**
 * Token status.
 */
@property(nonatomic, readonly, copy) NSString *status;

/**
 * Token expiration date .
 */
@property(nonatomic, readonly, copy) NSString *expiresOn;

/**
 * Account id.
 */
@property(nonatomic, readonly, copy, nullable) NSString *accountId;

/**
 * Initialize the Token result object
 *
 * @param partition Database partition
 * @param dbAccount Database account.
 * @param dbName Database name.
 * @param dbCollectionName Database collection name.
 * @param token Database token.
 * @param status Token status.
 * @param expiresOn Token expiration date
 * @return A token result instance.
 */
- (instancetype)initWithPartition:(NSString *)partition
                        dbAccount:(NSString *)dbAccount
                           dbName:(NSString *)dbName
                 dbCollectionName:(NSString *)dbCollectionName
                            token:(NSString *)token
                           status:(NSString *)status
                        expiresOn:(NSString *)expiresOn
                        accountId:(NSString *_Nullable)accountId;

/**
 * Initialize the Token result object
 *
 * @param tokenString Json String representing the token
 *
 * @return A token response instance.
 */
- (instancetype _Nullable)initWithString:(NSString *)tokenString;

/**
 * Initialize the Token result object
 *
 * @param token A dictionary the token properties
 *
 * @return A token response instance.
 */
- (instancetype _Nullable)initWithDictionary:(NSDictionary *)token;

/**
 * Serialize the token has a string.
 *
 * @return The serialized token (or nil in case of error).
 */
- (NSString *_Nullable)serializeToString;

@end

NS_ASSUME_NONNULL_END
