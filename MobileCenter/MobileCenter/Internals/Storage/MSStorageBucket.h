#import "MSFile.h"
#import "MSLog.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A class which manages the files inside a subdirectory on the file system.
 */
@interface MSStorageBucket : NSObject

/**
 * The file instance representing the current file used for adding new logs.
 */
@property(nonatomic, strong) MSFile *currentFile;

/**
 * A in-memory list of all items that have been added to the current batch.
 */
@property(nonatomic, strong) NSMutableArray<MSLog> *currentLogs;

/**
 * A list of file names that are currently used by other components.
 */
@property(nonatomic, strong) NSMutableArray<MSFile *> *blockedFiles;

/**
 * A list of file names that can be accessed by other components.
 */
@property(nonatomic, strong) NSMutableArray<MSFile *> *availableFiles;

/**
 * Returns the file with the given id.
 *
 * @param fileId the Id of the requested file
 *
 * @return the file for the given id
 */
- (MSFile *)fileWithId:(NSString *)fileId;

/**
 * Sorts the list of available files by creation date. The most recent file will
 * be at the last index.
 */
- (void)sortAvailableFilesByCreationDate;

/**
 * Removes the given file from the bucket's internal available or blocked list.
 *
 *  @param file The file to delete.
 */
- (void)removeFile:(MSFile *)file;

/**
 * Removes all files from the bucket's internal available or blocked list.
 *
 *  @return An array containing the removed files.
 */
- (NSArray<MSFile *> *)removeAllFiles;

@end

NS_ASSUME_NONNULL_END
