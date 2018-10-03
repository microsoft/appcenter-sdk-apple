#import <Foundation/Foundation.h>

#import "MSAppCenterInternal.h"
#import "MSLogger.h"
#import "MSUtility+File.h"

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityFileCategory;

/**
 * Bundle identifier, used for storage directories.
 */
static NSString *const kMSAppCenterBundleIdentifier = @"com.microsoft.appcenter";

@implementation MSUtility (File)

+ (NSURL *)createFileAtPathComponent:(NSString *)filePathComponent
                            withData:(NSData *)data
                          atomically:(BOOL)atomically
                      forceOverwrite:(BOOL)forceOverwrite {
  @synchronized(self) {
    if (filePathComponent) {
      NSURL *fileURL = [[self appCenterDirectoryURL] URLByAppendingPathComponent:filePathComponent];

      // Check if item already exists. We need to check this as writeToURL:atomically: can override an existing file.
      if (!forceOverwrite && [fileURL checkResourceIsReachableAndReturnError:nil]) {
        return fileURL;
      }

      // Create parent directories as needed.
      NSURL *directoryURL = [fileURL URLByDeletingLastPathComponent];
      [self createDirectoryAtURL:directoryURL];

      // Create the file.
      NSData *theData = (data != nil) ? data : [NSData data];
      if ([theData writeToURL:fileURL atomically:atomically]) {
        return fileURL;
      } else {
        MSLogError([MSAppCenter logTag], @"Couldn't create new file at path %@", fileURL);
      }
    }
    return nil;
  }
}

+ (BOOL)deleteItemForPathComponent:(NSString *)itemPathComponent {
  @synchronized(self) {
    if (itemPathComponent) {
      NSURL *itemURL = [[self appCenterDirectoryURL] URLByAppendingPathComponent:itemPathComponent];
      NSError *error = nil;
      BOOL succeeded;
      succeeded = [[NSFileManager defaultManager] removeItemAtURL:itemURL error:&error];
      if (error) {
        MSLogDebug([MSAppCenter logTag], @"Couldn't remove item at %@: %@", itemURL, error.localizedDescription);
      }
      return succeeded;
    }
    return NO;
  }
}

// TODO: We should remove this and just expose the method taking a pathComponent.
+ (BOOL)deleteFileAtURL:(NSURL *)fileURL {
  @synchronized(self) {
    if (fileURL) {

      /*
       * No need to check existence of directory as checkResourceIsReachableAndReturnError: is synchronous. From it's docs: "If your app
       * must perform operations on the file, such as opening it or copying resource properties, it is more efficient to attempt the
       * operation and handle any failure that may occur."
       */
      NSError *error = nil;
      BOOL succeeded;
      succeeded = [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
      if (error) {
        MSLogDebug([MSAppCenter logTag], @"Couldn't remove item at %@: %@", fileURL, error.localizedDescription);
      }
      return succeeded;
    }
    return NO;
  }
}

+ (NSURL *)createDirectoryForPathComponent:(NSString *)directoryPathComponent {
  @synchronized(self) {
    if (directoryPathComponent) {
      NSURL *subDirURL = [[self appCenterDirectoryURL] URLByAppendingPathComponent:directoryPathComponent];
      BOOL success = [self createDirectoryAtURL:subDirURL];
      return success ? subDirURL : nil;
    }
    return nil;
  }
}

+ (NSData *)loadDataForPathComponent:(NSString *)filePathComponent {
  @synchronized(self) {
    if (filePathComponent) {
      NSURL *fileURL = [[self appCenterDirectoryURL] URLByAppendingPathComponent:filePathComponent];
      return [NSData dataWithContentsOfURL:fileURL];
    }
    return nil;
  }
}

// TODO candidate for refactoring. Should return pathComponents and not full URLs. Has big impact on crashes logic.
+ (NSArray<NSURL *> *)contentsOfDirectory:(NSString *)directory propertiesForKeys:(NSArray *)propertiesForKeys {
  @synchronized(self) {
    if (directory && directory.length > 0) {
      NSFileManager *fileManager = [NSFileManager new];
      NSError *error = nil;
      NSURL *dirURL = [[self appCenterDirectoryURL] URLByAppendingPathComponent:directory isDirectory:YES];
      NSArray *files = [fileManager contentsOfDirectoryAtURL:dirURL
                                  includingPropertiesForKeys:propertiesForKeys
                                                     options:(NSDirectoryEnumerationOptions)0
                                                       error:&error];
      if (!files) {
        MSLogDebug([MSAppCenter logTag], @"Couldn't get files in the directory \"%@\": %@", directory, error.localizedDescription);
      }
      return files;
    }
    return nil;
  }
}

+ (BOOL)fileExistsForPathComponent:(NSString *)filePathComponent {
  {
    NSURL *fileURL = [[self appCenterDirectoryURL] URLByAppendingPathComponent:filePathComponent];
    return [fileURL checkResourceIsReachableAndReturnError:nil];
  }
}

+ (NSURL *)fullURLForPathComponent:(NSString *)filePathComponent {
  {
    if (filePathComponent) {
      return [[self appCenterDirectoryURL] URLByAppendingPathComponent:filePathComponent];
    }
    return nil;
  }
}

#pragma mark - Private methods.

+ (NSURL *)appCenterDirectoryURL {
  static NSURL *dirURL = nil;
  static dispatch_once_t predFilesDir;
  dispatch_once(&predFilesDir, ^{

#if TARGET_OS_TV
    NSSearchPathDirectory directory = NSCachesDirectory;
#else
    NSSearchPathDirectory directory = NSApplicationSupportDirectory;
#endif

    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray<NSURL *> *urls = [fileManager URLsForDirectory:directory inDomains:NSUserDomainMask];
    NSURL *baseDirUrl = [urls objectAtIndex:0];

#if TARGET_OS_OSX

    // Use the application's bundle identifier for macOS to make sure to use separate directories for each app.
    NSString *bundleIdentifier = [NSString stringWithFormat:@"%@/", [MS_APP_MAIN_BUNDLE bundleIdentifier]];
    dirURL = [[baseDirUrl URLByAppendingPathComponent:bundleIdentifier] URLByAppendingPathComponent:kMSAppCenterBundleIdentifier];
#else
    dirURL = [baseDirUrl URLByAppendingPathComponent:kMSAppCenterBundleIdentifier];
#endif
    [self createDirectoryAtURL:dirURL];
  });

  return dirURL;
}

+ (BOOL)createDirectoryAtURL:(NSURL *)fullDirURL {
  if (fullDirURL) {

    /*
     * No need to check existence of directory:
     *
     * 1. createDirectoryAtURL:withIntermediateDirectories:attributes:error: returns YES if the directory already exists.
     * 2. checkResourceIsReachableAndReturnError: is synchronous. From it's docs: "If your app must perform operations on the file, such as
     * opening it or copying resource properties, it is more efficient to attempt the operation and handle any failure that may occur."
     */
    NSError *error = nil;
    if ([[NSFileManager defaultManager] createDirectoryAtURL:fullDirURL withIntermediateDirectories:YES attributes:nil error:&error]) {
      [self disableBackupForDirectoryURL:fullDirURL];
      return YES;
    } else {
      MSLogError([MSAppCenter logTag], @"Couldn't create directory at %@: %@", fullDirURL, error.localizedDescription);
    }
  }
  return NO;
}

+ (BOOL)disableBackupForDirectoryURL:(nonnull NSURL *)directoryURL {
  NSError *error = nil;

  // SDK files shouldn't be backed up in iCloud.
  if (!directoryURL || ![directoryURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error]) {
    MSLogError([MSAppCenter logTag], @"Error excluding %@ from iCloud backup %@", directoryURL, error.localizedDescription);
    return NO;
  } else {
    return YES;
  }
}

@end
