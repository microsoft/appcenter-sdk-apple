#import "MSWrapperExceptionManager.h"

@class MSErrorReport;
@class MSWrapperException;

@interface MSWrapperExceptionManager ()

/**
 * Delete all wrapper exception files on disk.
 */
+ (void)deleteAllWrapperExceptions;

/**
 * Find the PLCrashReport with a matching process id to the MSWrapperException that was last saved on disk, and update the filename to the
 * report's UUID.
 */
+ (void)correlateLastSavedWrapperExceptionToReport:(NSArray<MSErrorReport *> *)reports;

/**
 * Delete a wrapper exception with a given UUID.
 */
+ (void)deleteWrapperExceptionWithUUIDString:(NSString *)uuidString;

@end
