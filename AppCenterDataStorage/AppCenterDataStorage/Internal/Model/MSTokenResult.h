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
 * Initialize the Token result object
 *
 * @param partition Databade partition
 * @param tokens Database account.
 * @param tokens Database name.
 * @param tokens Database collection name.
 * @param tokens Database token.
 * @param tokens Token sataus.
 *
 * @return An token response instance.
 */
- (instancetype)initWithPartition:(NSString *)partition
                        dbAccount:(NSString *)dbAccount
                           dbName:(NSString *)dbName
                 dbCollectionName:(NSString *)dbCollectionName
                            token:(NSString *)token
                           status:(NSString *)status;
@end
