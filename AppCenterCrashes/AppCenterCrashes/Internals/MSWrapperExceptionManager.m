#import "MSCrashesInternal.h"
#import "MSCrashesUtil.h"
#import "MSException.h"
#import "MSUtility+File.h"
#import "MSWrapperExceptionInternal.h"
#import "MSWrapperExceptionManagerInternal.h"

@implementation MSWrapperExceptionManager : NSObject

static NSString *const kMSLastWrapperExceptionFileName = @"last_saved_wrapper_exception";
static NSMutableDictionary *unprocessedWrapperExceptions;

+ (void)load {
  unprocessedWrapperExceptions = [NSMutableDictionary new];
}

#pragma mark Public Methods

/**
 * Gets a wrapper exception with a given UUID.
 */
+ (MSWrapperException *)loadWrapperExceptionWithUUIDString:(NSString *)uuidString {
  MSWrapperException *foundException = unprocessedWrapperExceptions[uuidString];
  return foundException ? foundException : [self loadWrapperExceptionWithBaseFilename:uuidString];
}

/**
 * Saves a wrapper exception to disk. Should only be used by wrapper SDK.
 */
+ (void)saveWrapperException:(MSWrapperException *)wrapperException {
  [self saveWrapperException:wrapperException withBaseFilename:kMSLastWrapperExceptionFileName];
}

#pragma mark Internal Methods

/**
 * Deletes a wrapper exception with a given UUID.
 */
+ (void)deleteWrapperExceptionWithUUIDString:(NSString *)uuidString {
  [self deleteWrapperExceptionWithBaseFilename:uuidString];
}

/**
 * Deletes all wrapper exceptions on disk.
 */
+ (void)deleteAllWrapperExceptions {
  [MSUtility deleteItemForPathComponent:[MSCrashesUtil wrapperExceptionsDir]];
}

/**
 * Renames the last saved wrapper exception with the error ID of the corresponding report in the given array. Pairing is based on the
 * process id of the error report.
 */
+ (void)correlateLastSavedWrapperExceptionToReport:(NSArray<MSErrorReport *> *)reports {
  MSWrapperException *lastSavedWrapperException = [self loadWrapperExceptionWithBaseFilename:kMSLastWrapperExceptionFileName];

  // Delete the last saved exception from disk if it exists.
  if (lastSavedWrapperException) {
    [self deleteWrapperExceptionWithBaseFilename:kMSLastWrapperExceptionFileName];
  }
  MSErrorReport *correspondingReport = nil;
  for (MSErrorReport *report in reports) {
    if ([lastSavedWrapperException.processId unsignedLongValue] == report.appProcessIdentifier) {
      correspondingReport = report;
      break;
    }
  }
  if (correspondingReport) {

    // As soon as the wrapper exception is correlated, store it in memory and save it to disk
    unprocessedWrapperExceptions[correspondingReport.incidentIdentifier] = lastSavedWrapperException;
    [self saveWrapperException:lastSavedWrapperException withBaseFilename:correspondingReport.incidentIdentifier];
  }
}

#pragma mark Helper methods

/**
 * Saves a wrapper exception to disk with the given file name.
 */
+ (void)saveWrapperException:(MSWrapperException *)wrapperException withBaseFilename:(NSString *)baseFilename {

  // For some reason, archiving directly to a file fails in some cases, so archive to NSData and write that to the file
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:wrapperException];
  NSString *pathComponent = [NSString stringWithFormat:@"%@/%@", [MSCrashesUtil wrapperExceptionsDir], baseFilename];
  [MSUtility createFileAtPathComponent:pathComponent withData:data atomically:YES forceOverwrite:YES];
}

/**
 * Deletes a wrapper exception with a given file name.
 */
+ (void)deleteWrapperExceptionWithBaseFilename:(NSString *)baseFilename {
  NSString *pathComponent = [NSString stringWithFormat:@"%@/%@", [MSCrashesUtil wrapperExceptionsDir], baseFilename];
  [MSUtility deleteItemForPathComponent:pathComponent];
}

/**
 * Loads a wrapper exception with a given filename.
 */
+ (MSWrapperException *)loadWrapperExceptionWithBaseFilename:(NSString *)baseFilename {

  // For some reason, unarchiving directly from a file fails in some cases, so load data from a file and unarchive it after
  NSString *pathComponent = [NSString stringWithFormat:@"%@/%@", [MSCrashesUtil wrapperExceptionsDir], baseFilename];
  NSData *data = [MSUtility loadDataForPathComponent:pathComponent];
  MSWrapperException *wrapperException = nil;
  @try {
    wrapperException = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  } @catch (__attribute__((unused)) NSException *exception) {
    MSLogError([MSCrashes logTag], @"Could not read exception data stored on disk with file name %@", baseFilename);
    [self deleteWrapperExceptionWithBaseFilename:baseFilename];
  }
  return wrapperException;
}

@end
