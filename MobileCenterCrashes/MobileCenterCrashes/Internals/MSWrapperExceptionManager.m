#import "MSCrashesInternal.h"
#import "MSErrorReport.h"
#import "MSException.h"
#import "MSUtility+File.h"
#import "MSWrapperExceptionInternal.h"
#import "MSWrapperExceptionManagerInternal.h"

@implementation MSWrapperExceptionManager : NSObject

static NSString* const kDirectoryName = @"mc_wrapper_exceptions";
static NSString* const kLastWrapperExceptionFileName = @"last_saved_wrapper_exception";

/**
 * Initialize the class.
 */
+ (void)initialize {
  if (![[NSFileManager defaultManager] fileExistsAtPath:[self directoryPath]]) {
    NSURL *directoryUrl = [NSURL URLWithString:[self directoryPath]];
    [MSUtility createDirectoryAtURL:directoryUrl];
  }
}

#pragma mark Public Methods

/**
 * Gets a wrapper exception with a given UUID.
 */
+ (MSWrapperException *)loadWrapperExceptionWithUUID:(NSString *)uuid {
  return [self loadWrapperExceptionWithBaseFilename:uuid];
}

/**
 * Saves a wrapper exception to disk. Should only be used by wrapper SDK.
 */
+ (void)saveWrapperException:(MSWrapperException *)wrapperException {
  [self saveWrapperException:wrapperException withBaseFilename:kLastWrapperExceptionFileName];
}

#pragma mark Internal Methods

/**
 * Deletes a wrapper exception with a given UUID.
 */
+ (void)deleteWrapperExceptionWithUUID:(NSString *)uuid {
  [self deleteWrapperExceptionWithBaseFilename:uuid];
}

/**
 * Deletes all wrapper exceptions on disk.
 */
+ (void)deleteAllWrapperExceptions {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  for (NSString *filePath in [fileManager enumeratorAtPath:[self directoryPath]]) {
    NSString *path = [self getFilename:filePath];
    NSURL *url = [NSURL URLWithString:path];
    [MSUtility removeItemAtURL:url];
  }
}

/**
 * Renames the last saved wrapper exception with the error ID of the
 * corresponding report in the given array. Pairing is based on the process
 * id of the error report.
 */
+ (void)correlateLastSavedWrapperExceptionToReport:(NSArray<MSErrorReport*> *)reports {
  MSWrapperException *lastSavedWrapperException = [self loadWrapperExceptionWithBaseFilename:kLastWrapperExceptionFileName];

  // Delete the last saved exception from disk if it exists.
  if (lastSavedWrapperException) {
    [self deleteWrapperExceptionWithBaseFilename:kLastWrapperExceptionFileName];
  }
  MSErrorReport *correspondingReport = nil;
  for (MSErrorReport *report in reports) {
    if ([lastSavedWrapperException.processId unsignedLongValue] == report.appProcessIdentifier) {
      correspondingReport = report;
      break;
    }
  }
  if (correspondingReport) {
    [self saveWrapperException:lastSavedWrapperException withBaseFilename:correspondingReport.incidentIdentifier];
  }
}

#pragma mark Helper methods

/**
 * Saves a wrapper exception to disk with the given file name.
 */
+ (void)saveWrapperException:(MSWrapperException *)wrapperException withBaseFilename:(NSString *)baseFilename {
  NSString *exceptionFilename = [self getFilename:baseFilename];
  BOOL success = [NSKeyedArchiver archiveRootObject:wrapperException toFile:exceptionFilename];
  if (!success) {
    MSLogError([MSCrashes logTag], @"Failed to save wrapper SDK exception file %@", exceptionFilename);
  }
}

/**
 * Deletes a wrapper exception with a given file name.
 */
+ (void)deleteWrapperExceptionWithBaseFilename:(NSString *)baseFilename
{
  for (NSString *filePath in [[NSFileManager defaultManager] enumeratorAtPath:[self directoryPath]]) {
    NSString *actualPath = [self getFilename:filePath];
    NSString *expectedPath = [self getFilename:baseFilename];
    if ([actualPath isEqualToString:expectedPath]) {
      NSURL *url = [NSURL URLWithString:actualPath];
      [MSUtility removeItemAtURL:url];
      return;
    }
  }
}

/**
 * Loads a wrapper exception with a given filename.
 */
+ (MSWrapperException *)loadWrapperExceptionWithBaseFilename:(NSString *)baseFilename {
  NSString *exceptionFilename = [self getFilename:baseFilename];
  MSWrapperException *wrapperException = [NSKeyedUnarchiver unarchiveObjectWithFile:exceptionFilename];
  return wrapperException;
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
  return [[self directoryPath] stringByAppendingPathComponent:filename];
}


@end
