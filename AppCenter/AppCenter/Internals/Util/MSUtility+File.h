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
 * Creates a file inside the app center sdk's file directory, intermediate directories are also create if nonexistent.
 *
 * @param filePathComponent A string representing the path of the file to create.
 * @param data The data to write to the file.
 * @param atomically Flag to indicate atomic write or not.
 * @param forceOverwrite Flag to make this method overwrite existing files.
 *
 * @return The URL of the file that was created. Necessary for e.g. crash buffer.
 *
 * @discussion SDK files should not be backed up in iCloud. Thus, iCloud backup is explicitely
 * deactivated on every folder created.
 */
+ (NSURL *)createFileAtPathComponent:(NSString *)filePathComponent withData:(NSData *)data atomically:(BOOL)atomically forceOverwrite:(BOOL)forceOverwrite;

/**
 * Removes the file or directory specified inside the app center sdk directory.
 *
 * @param itemPathComponent A string representing the path of the file to create.
 *
 * @return YES if the item was removed successfully or if URL was nil. Returns NO if an error occurred.
 */
+ (BOOL)removeItemForPathComponent:(NSString *)itemPathComponent;

/**
 * Creates a directory inside the app center sdk's file directory, intermediate directories are also created if nonexistent.
 *
 * @param subDirectoryPathComponent A string representing the path of the directory to create.
 *
 * @return `YES` if the operation was successful or if the item already exists, otherwise `NO`.
 *
 * @discussion SDK files should not be backed up in iCloud. Thus, iCloud backup is explicitely
 * deactivated on every folder created.
 */
+ (BOOL)createSubDirectoryForPathComponent:(NSString *)subDirectoryPathComponent;

+ (NSData *)loadDataForPathComponent:(NSString *)filePathComponent;

//TODO this returns NSURLS because...crashes needs this.
+ (NSArray <NSURL *>*)contentsOfDirectory:(NSString *)subDirectory propertiesForKeys:(NSArray *)propertiesForKeys;

+ (BOOL)fileExistsForPathComponent:(NSString *)filePathComponent;

//TODO remove this? used in crashes
+ (BOOL)removeFileAtURL:(NSURL *)fileURL;

+ (NSURL *)fullURLForPathComponent:(NSString *)filePathComponent;

@end

