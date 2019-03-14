#import <Foundation/Foundation.h>

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
                        expiresOn:(NSString *)expiresOn;

/**
 * Initialize the Token result object
 *
 * @param tokenString Json String representing the token
 *
 * @return A token response instance.
 */
- (instancetype)initWithString:(NSString *)tokenString;

/**
 * Initialize the Token result object
 *
 * @param tokens A dictionary the token properties
 *
 * @return A token response instance.
 */
- (instancetype)initWithDictionary:(NSDictionary *)tokens;

- (NSString *)serializeToString;

@end
