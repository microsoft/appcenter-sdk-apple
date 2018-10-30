#import "MSEncrypter.h"
#import "MSLogDBStorage.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kMSDBFileName = @"Logs.sqlite";
static NSString *const kMSLogTableName = @"logs";
static NSString *const kMSIdColumnName = @"id";
static NSString *const kMSGroupIdColumnName = @"groupId";
static NSString *const kMSLogColumnName = @"log";
static NSString *const kMSTargetTokenColumnName = @"targetToken";
static NSString *const kMSTargetKeyColumnName = @"targetKey";
static NSString *const kMSPriorityColumnName = @"priority";

@protocol MSDatabaseConnection;

@interface MSLogDBStorage ()

/**
 * Keep track of logs batches per group Id associated with their logs Ids.
 */
@property(nonatomic) NSMutableDictionary<NSString *, NSArray<NSNumber *> *> *batches;

/**
 * "id" database column index.
 */
@property(nonatomic, readonly) NSUInteger idColumnIndex;

/**
 * "groupId" database column index.
 */
@property(nonatomic, readonly) NSUInteger groupIdColumnIndex;

/**
 * "log" database column index.
 */
@property(nonatomic, readonly) NSUInteger logColumnIndex;

/**
 * "targetToken" database column index.
 */
@property(nonatomic, readonly) NSUInteger targetTokenColumnIndex;

/*
 * Encrypter for target tokens.
 */
@property(nonatomic, readonly) MSEncrypter *targetTokenEncrypter;

/**
 * Get all logs with the given group Id from the storage.
 *
 * @param groupId The key used for grouping logs.
 *
 * @return Logs and their ids corresponding to the given group Id from the storage.
 */
- (NSArray<id<MSLog>> *)logsFromDBWithGroupId:(NSString *)groupId;

@end

NS_ASSUME_NONNULL_END
