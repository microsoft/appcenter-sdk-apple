#import <Foundation/Foundation.h>

@interface MSTokenResult : NSObject

@property (nonatomic, readonly) NSString *partition;
@property (nonatomic, readonly) NSString *dbAccount;
@property (nonatomic, readonly) NSString *dbName;
@property (nonatomic, readonly) NSString *dbCollectionName;
@property (nonatomic, readonly) NSString *token;
@property (nonatomic, readonly) NSString *status;

- (instancetype)initWithPartition:(NSString *)partition
                     andDbAccount:(NSString *)dbAccount
                        andDbName:(NSString *)dbName
              andDbCollectionName:(NSString *)dbCollectionName
                         andToken:(NSString *)token
                        andStatus:(NSString *)status;

@end
