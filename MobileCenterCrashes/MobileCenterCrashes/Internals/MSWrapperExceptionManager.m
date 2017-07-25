#import "MSWrapperExceptionManagerInternal.h"
#import "MSCrashesInternal.h"
#import "MSException.h"
#import "MSWrapperExceptionInternal.h"

#import <CrashReporter/CrashReporter.h>

@implementation MSWrapperExceptionManager : NSObject

static NSString* const kDirectoryName = @"mc_wrapper_exceptions";
static NSString* const kLastWrapperExceptionFileName = @"last_saved_wrapper_exception";

/**
 * Initialize the class.
 */
+ (void) initialize {
  // Create the directory if it doesn't exist
  NSFileManager *defaultManager = [NSFileManager defaultManager];

  if (![defaultManager fileExistsAtPath:[[self class] directoryPath]]) {
    NSError *error = nil;
    [defaultManager createDirectoryAtPath:[[self class] directoryPath]
              withIntermediateDirectories:NO
                               attributes:nil
                                    error:&error];
    if (error) {
      MSLogError([MSCrashes logTag], @"Failed to create directory %@: %@", [[self class] directoryPath],
                 error.localizedDescription);
    }
  }
}

#pragma mark Public Methods

/**
 * Gets a wrapper exception with a given UUID.
 */
+ (MSWrapperException *) loadWrapperExceptionWithUUID:(NSString *)uuid {
  return [self loadWrapperExceptionWithBaseFilename:uuid]];
}

/**
 * Saves a wrapper exception to disk. Should only be used by wrapper SDK.
 */
+ (void) saveWrapperException:(MSWrapperException *)wrapperException {
  [self saveWrapperException:wrapperException withBaseFilename:kLastWrapperExceptionFileName];
}

#pragma mark Internal Methods

/**
 * Deletes a wrapper exception with a given UUID.
 */
+ (void) deleteWrapperExceptionWithUUID:(NSString *)uuid {
  [self deleteWrapperExceptionWithBaseFilename:uuid];
}

/**
 * Deletes a wrapper exception with a given CFUUIDRef.
 */
+ (void) deleteWrapperExceptionWithUUIDRef:(CFUUIDRef)uuidRef {
  [self deleteWrapperExceptionWithBaseFilename:[self uuidRefToString:uuidRef]];
}

/**
 * Gets a wrapper exception with a given CFUUIDRef.
 */
+ (MSWrapperException *) loadWrapperExceptionWithUUIDRef:(CFUUIDRef)uuidRef {
  return [self loadWrapperExceptionWithBaseFilename:[self uuidRefToString:uuidRef]];
}

/**
 * Deletes all wrapper exceptions on disk.
 */
+ (void)deleteAllWrapperExceptions {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  for (NSString *filePath in [fileManager enumeratorAtPath:[[self class] directoryPath]]) {
      NSString *path = [[[self class] directoryPath] stringByAppendingPathComponent:filePath];
      [[self class] deleteFile:path];
  }
}

/**
 * Renames the last saved wrapper exception with the error ID of the
 * corresponding report in the given array.
 */
+ (void) correlateLastSavedWrapperExceptionToReport:(NSArray<MSPLCrashReport*> *)reports
{
  MSWrapperException *lastSavedWrapperException = [self loadWrapperExceptionWithBaseFilename:kLastWrapperExceptionFileName];

  // Delete the last saved exception from disk if it exists
  if (lastSavedWrapperException) {
    [self deleteWrapperExceptionWithBaseFilename:kLastWrapperExceptionFileName];
  }

  MSPLCrashReport * correspondingReport = nil;
  for (MSPLCrashReport * report in reports) {
    if ([report hasProcessInfo] &&
        [lastSavedWrapperException.processId unsignedIntegerValue] == report.processInfo.processID){
      correspondingReport = report;
      break;
    }
  }
  if (correspondingReport) {
    NSString* uuidString = [[self class] uuidRefToString:correspondingReport.uuidRef];
    [self saveWrapperException:lastSavedWrapperException withBaseFilename:uuidString];
  }
}

#pragma mark Helper methods

/**
 * Saves a wrapper exception to disk with the given file name.
 */
+ (void) saveWrapperException:(MSWrapperException *)wrapperException withBaseFilename:(NSString *)baseFilename {
  NSString *exceptionFilename = [[self class] getFilename:baseFilename];
  BOOL success = [NSKeyedArchiver archiveRootObject:wrapperException toFile:exceptionFilename];
  if (!success) {
    MSLogError([MSCrashes logTag], @"Failed to save wrapper SDK exception file %@", exceptionFilename);
  }
}

/**
 * Deletes a wrapper exception with a given file name.
 */
+ (void) deleteWrapperExceptionWithBaseFilename:(NSString *)baseFilename
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  for (NSString *filePath in [fileManager enumeratorAtPath:[[self class] directoryPath]]) {
    NSString *actualPath = [[[self class] directoryPath] stringByAppendingPathComponent:filePath];
    NSString *expectedPath = [[self class] getFilename:baseFilename];
    if ([actualPath isEqualToString:expectedPath]) {
      [[self class] deleteFile:actualPath];
      return;
    }
  }
}

/**
 * Loads a wrapper exception with a given filename.
 */
+ (MSWrapperException *) loadWrapperExceptionWithBaseFilename:(NSString *)baseFilename {
  NSString *exceptionFilename = [self getFilename:baseFilename];
  MSWrapperException * wrapperException = [NSKeyedUnarchiver unarchiveObjectWithFile:exceptionFilename];
  return wrapperException;
}

/**
 * Deletes the file at the given path.
 */
+ (void)deleteFile:(NSString *)path {
  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
    return;
  }
  NSError *error = nil;
  [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
  if (error) {
    MSLogError([MSCrashes logTag], @"Error deleting file %@: %@", path, error.localizedDescription);
  }
}

/**
 * Gets the directory path for wrapper exceptions.
 */
+ (NSString *)directoryPath {

  // Only compute path the first time this method is called.
  static NSString *path = nil;
  if (!path) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    path = [documentsDirectory stringByAppendingPathComponent:kDirectoryName];
  }
  return path;
}

/**
 * Gets the full path for a given file name that should be in the wrapper crashes directory.
 */
+ (NSString *)getFilename:(NSString *)filename {
  return [[[self class] directoryPath] stringByAppendingPathComponent:filename];
}

/**
 * Converts the given CFUUIDRef to an NSString*.
 */
+ (NSString *)uuidRefToString:(CFUUIDRef)uuidRef {
  if (!uuidRef) {
    return nil;
  }
  CFStringRef uuidStringRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
  return (__bridge_transfer NSString *)uuidStringRef;
}

@end
