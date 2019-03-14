#import <Foundation/Foundation.h>

@interface MSTokenResult : NSObject

/**
 * Partition.
 */
@property(nonatomic, readonly) NSString *partition;

/**
 * Database account.
 */
@property(nonatomic, readonly) NSString *dbAccount;

/**
 * Database name.
 */
@property(nonatomic, readonly) NSString *dbName;

/**
 * Database collection Name.
 */
@property(nonatomic, readonly) NSString *dbCollectionName;

/**
 * Database access token.
 */
@property(nonatomic, readonly) NSString *token;

/**
 * Token status.
 */
@property(nonatomic, readonly) NSString *status;

/**
 * Token expiration date .
 */
@property(nonatomic, readonly) NSString *expiresOn;

/**
 * Initialize the Token result object
 *
 * @param partition Database partition
 * @param dbAccount Database account.
 * @param dbName Database name.
 * @param dbCollectionName Database collection name.
 * @param token Database token.
 * @param status Token sataus.
 *
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
