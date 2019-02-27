#import <Foundation/Foundation.h>

@interface MSTokenResult : NSObject

@property(nonatomic, readonly) NSString *partition;
@property(nonatomic, readonly) NSString *dbAccount;
@property(nonatomic, readonly) NSString *dbName;
@property(nonatomic, readonly) NSString *dbCollectionName;
@property(nonatomic, readonly) NSString *token;
@property(nonatomic, readonly) NSString *status;

- (instancetype)initWithPartition:(NSString *)partition
                        dbAccount:(NSString *)dbAccount
                           dbName:(NSString *)dbName
                 dbCollectionName:(NSString *)dbCollectionName
                            token:(NSString *)token
                           status:(NSString *)status;

@end
