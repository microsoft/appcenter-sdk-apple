#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSUtility+File.h"

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityFileCategory;

@implementation MSUtility (File)

+ (BOOL)createFileAtURL:(NSURL *)fileURL {
  if (fileURL) {

    // Check if file already exists.
    if ([fileURL checkResourceIsReachableAndReturnError:nil]) {
      return YES;
    }

    // Create parent directories as needed.
    NSURL *directoryURL = [fileURL URLByDeletingLastPathComponent];
    if (![directoryURL checkResourceIsReachableAndReturnError:nil]) {
      [self createDirectoryAtURL:directoryURL];
    }

    // Create the file.
    if ([[NSData data] writeToURL:fileURL atomically:NO]) {
      return YES;
    } else {
      MSLogError([MSMobileCenter logTag], @"Couldn't create new file at path %@", fileURL);
    }
  }
  return NO;
}

+ (BOOL)createDirectoryAtURL:(NSURL *)directoryURL {
  if (directoryURL) {

    // Create directory also create parent directories if they don't exist.
    NSError *error = nil;
    if ([[NSFileManager defaultManager] createDirectoryAtURL:directoryURL
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&error]) {
      [self disableBackupForDirectoryURL:directoryURL];
      return YES;
    } else {
      MSLogError([MSMobileCenter logTag], @"Couldn't create directory at path %@: %@", directoryURL,
                 error.localizedDescription);
    }
  }
  return NO;
}

+ (BOOL)removeItemAtURL:(NSURL *)itemURL {
  NSError *error = NULL;
  BOOL succeeded;
  succeeded = [[NSFileManager defaultManager] removeItemAtURL:itemURL error:&error];
  if (error) {
    MSLogError([MSMobileCenter logTag], @"Couldn't remove item at path %@: %@", itemURL, error.localizedDescription);
  }
  return succeeded;
}

+ (BOOL)disableBackupForDirectoryURL:(nonnull NSURL *)directoryURL {
  NSError *error = nil;

  // SDK files shouldn't be backed up in iCloud.
  if (!directoryURL || ![directoryURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error]) {
    MSLogError([MSMobileCenter logTag], @"Error excluding %@ from iCloud backup %@", directoryURL,
               error.localizedDescription);
    return NO;
  } else {
    return YES;
  }
}

@end
