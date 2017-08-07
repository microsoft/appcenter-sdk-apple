#import <Foundation/Foundation.h>
#import "MSUtility.h"

/*
 * Workaround for exporting symbols from category object files.
 */
extern NSString *MSUtilityFileCategory;

/**
 * Utility class that is used throughout the SDK.
 * File part.
 */
@interface MSUtility (File)

/**
 * Creates a file at the given location, intermediate directories are also create if nonexistent.
 *
 * @param fileURL URL representing the absolute path of the file to create.
 *
 * @return `YES` if the operation was successful or if the item already exists, otherwise `NO`.
 *
 * @discussion SDK files should not be backed up in iCloud. Thus, iCloud backup is explicitely
 * deactivated on every folder created.
 */
+ (BOOL)createFileAtURL:(NSURL *)fileURL;

/**
 * Removes the file or directory at the specified URL.
 *
 * @param itemURL URL representing the absolute path of the file to create.
 *
 * @return YES if the item was removed successfully or if URL was nil. Returns NO if an error occurred.
 */
+ (BOOL)removeItemAtURL:(NSURL *)itemURL;

/**
* Creates a directory at the given location, intermediate directories are also created if nonexistant.
*
* @param directoryURL URL representing the absolute path of the directory to create.
*
* @return `YES` if the operation was successful or if the item already exists, otherwise `NO`.
*
* @discussion SDK files should not be backed up in iCloud. Thus, iCloud backup is explicitely
* deactivated on every folder created.
*/
+ (BOOL)createDirectoryAtURL:(NSURL *)directoryURL;

@end
