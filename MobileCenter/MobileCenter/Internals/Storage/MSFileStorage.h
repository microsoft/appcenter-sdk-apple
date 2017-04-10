#import "MSStorage.h"
#import "MSStorageBucket.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSFileStorage : NSObject <MSStorage>

/**
 * The directory for saving SDK related files within the app's folder.
 */
@property(nonatomic, copy) NSURL *baseDirectoryURL;

/**
 * A dictionary containing file names and their status for certain storage keys.
 */
@property(nonatomic) NSMutableDictionary<NSString *, MSStorageBucket *> *buckets;

/**
 * Returns the file path to a log file based on its id and storage key.
 *
 * @param groupID A groupID which identifies the group of the log file.
 * @param logsId The internal Id of the file.
 *
 * @return the file url
 */
- (NSURL *) fileURLForGroupID:(NSString *)groupID logsId:(NSString *)logsId;

/**
 * Returns the bucket for a given storage key or creates a new one if it doesn't exist, yet.
 *
 * @param groupID The groupID for the bucket.
 *
 * @return The bucket for a given storage key.
 */
- (MSStorageBucket *)bucketForGroupID:(NSString *)groupID;

@end

NS_ASSUME_NONNULL_END
