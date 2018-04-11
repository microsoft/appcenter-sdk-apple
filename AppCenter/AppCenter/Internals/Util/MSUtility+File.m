#import "MSAppCenterInternal.h"
#import "MSLogger.h"
#import "MSUtility+File.h"

#import <Foundation/Foundation.h>

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityFileCategory;

/**
 * Bundle identifier, used for storage directories.
 */
static NSString *const kMSAppCenterBundleIdentifier = @"com.microsoft.appcenter";

@implementation MSUtility (File)

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
    NSURL *cacheDirURL = [urls objectAtIndex:0];

#if TARGET_OS_OSX

    // Use the application's bundle identifier for macOS to make sure to use separate directories for each app.
    NSString *bundleIdentifier = [MS_APP_MAIN_BUNDLE bundleIdentifier];
    dirURL = [[cacheDirURL URLByAppendingPathComponent:bundleIdentifier]
        URLByAppendingPathComponent:kMSAppCenterBundleIdentifier];
#else
      dirURL = [cacheDirURL URLByAppendingPathComponent:kMSAppCenterBundleIdentifier];
#endif
    if (![dirURL checkResourceIsReachableAndReturnError:nil]) {
      [self createDirectoryAtURL:dirURL];
    }
  });

  return dirURL;
}

+ (NSURL *)createFileAtPathComponent:(NSString *)filePathComponent withData:(NSData *)data atomically:(BOOL)atomically forceOverwrite:(BOOL)forceOverwrite async:(BOOL)async{
  if (filePathComponent) {
    NSURL *fileURL = [[self appCenterDirectoryURL] URLByAppendingPathComponent:filePathComponent];

    // Check if item already exists.
    if (!forceOverwrite && [fileURL checkResourceIsReachableAndReturnError:nil]) {
      return fileURL;
    }
    
    if(async) {
      dispatch_queue_t bufferFileQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
      dispatch_group_t bufferFileGroup = dispatch_group_create(); //TODO this creates a queue with 1 file
      
      dispatch_group_async(bufferFileGroup, bufferFileQueue, ^{
        // Create parent directories as needed.
        NSURL *directoryURL = [fileURL URLByDeletingLastPathComponent];
        if (![directoryURL checkResourceIsReachableAndReturnError:nil]) {
          [self createDirectoryAtURL:directoryURL];
        }
        
        // Create the file.
        NSData *theData = (data != nil) ? data : [NSData data];
        if ([theData writeToURL:fileURL atomically:atomically]) {
        } else {
          MSLogError([MSAppCenter logTag], @"Couldn't create new file at path %@", fileURL);
        }
        
      });
      return fileURL;
    } else {
      // Create parent directories as needed.
      NSURL *directoryURL = [fileURL URLByDeletingLastPathComponent];
      if (![directoryURL checkResourceIsReachableAndReturnError:nil]) {
        [self createDirectoryAtURL:directoryURL];
      }
      
      // Create the file.
      NSData *theData = (data != nil) ? data : [NSData data];
      if ([theData writeToURL:fileURL atomically:atomically]) {
        return fileURL;
      } else {
        MSLogError([MSAppCenter logTag], @"Couldn't create new file at path %@", fileURL);
      }
    }
  }
  return nil;
}

+ (BOOL)removeItemForPathComponent:(NSString *)itemPathComponent {
  if (itemPathComponent) {
    NSURL *itemURL = [[self appCenterDirectoryURL] URLByAppendingPathComponent:itemPathComponent];
    NSError *error = nil;
    BOOL succeeded;
    succeeded = [[NSFileManager defaultManager] removeItemAtURL:itemURL error:&error];
    if (error) {
      MSLogError([MSAppCenter logTag], @"Couldn't remove item at %@: %@", itemURL, error.localizedDescription);
    }
    return succeeded;
  }
  return NO;
}

+ (BOOL)removeFileAtURL:(NSURL *)fileURL {
  if (fileURL && [fileURL checkResourceIsReachableAndReturnError:nil]) {
    NSError *error = nil;
    BOOL succeeded;
    succeeded = [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
    if (error) {
      MSLogError([MSAppCenter logTag], @"Couldn't remove item at %@: %@", fileURL, error.localizedDescription);
    }
    return succeeded;
  }
  return NO;
}

+ (BOOL)createSubDirectoryForPathComponent:(NSString *)subDirectoryPathComponent {
  if (subDirectoryPathComponent) {
    NSURL *subDirURL = [[self appCenterDirectoryURL] URLByAppendingPathComponent:subDirectoryPathComponent];
    return [self createDirectoryAtURL:subDirURL];
  }
  return NO;
}

+ (NSData *)loadDataForPathComponent:(NSString *)filePathComponent {
  if (filePathComponent) {
    NSURL *fileURL = [[self appCenterDirectoryURL] URLByAppendingPathComponent:filePathComponent];
    return [NSData dataWithContentsOfURL:fileURL];
  }
  return nil;
}

+ (void)createDBWithFileName:(NSString *)filename {
  if (filename) {
    [MSUtility createFileAtPathComponent:filename withData:nil atomically:NO forceOverwrite:NO async:NO]; //TODO check forceoverwrite?
  }
}

+ (NSString *)pathToDBWithFileName:(NSString *)fileName {
  NSURL *path = [self appCenterDirectoryURL];
  NSURL *dbURL = [path URLByAppendingPathComponent:fileName];
  if ([dbURL checkResourceIsReachableAndReturnError:nil]) {
    return [dbURL absoluteString];
  } else {
    return nil;
  }
}

// TODO return path components/fileName, and not URLs
+ (NSArray <NSURL *>*)contentsOfDirectory:(NSString *)subDirectory propertiesForKeys:(NSArray *)propertiesForKeys {
  if (subDirectory && subDirectory.length > 0) {
    NSFileManager *fileManager = [NSFileManager new];
    NSError *error = nil;
    NSURL *dirURL = [[self appCenterDirectoryURL] URLByAppendingPathComponent:subDirectory isDirectory:YES];
    NSArray *files = [fileManager contentsOfDirectoryAtURL:dirURL
                                includingPropertiesForKeys:propertiesForKeys
                                                   options:(NSDirectoryEnumerationOptions)0
                                                     error:&error];
    if (!files) {
      MSLogError([MSAppCenter logTag], @"Couldn't get files in the directory \"%@\": %@", subDirectory,
                 error.localizedDescription);
    }
    return files;
  }
  return nil;
}

+ (BOOL)fileExistsForPathComponent:(NSString *)filePathComponent {
  NSURL *fileURL = [[self appCenterDirectoryURL] URLByAppendingPathComponent:filePathComponent];
  return [fileURL checkResourceIsReachableAndReturnError:nil];
}


#pragma mark - Private methods.

+ (BOOL)createDirectoryAtURL:(NSURL *)fullDirURL {
  if (fullDirURL) {
    if ([fullDirURL checkResourceIsReachableAndReturnError:nil]) {
      return YES;
    }

    // Create directory also create parent directories if they don't exist.
    NSError *error = nil;
    if ([[NSFileManager defaultManager] createDirectoryAtURL:fullDirURL
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&error]) {
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
    MSLogError([MSAppCenter logTag], @"Error excluding %@ from iCloud backup %@", directoryURL,
               error.localizedDescription);
    return NO;
  } else {
    return YES;
  }
}

@end
