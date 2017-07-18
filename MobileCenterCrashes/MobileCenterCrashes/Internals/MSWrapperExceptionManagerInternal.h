#import "MSWrapperExceptionManager.h"

@class MSWrapperException;
@class MSPLCrashReport;

@interface MSWrapperExceptionManager ()
+ (void)deleteAllWrapperExceptions;
+ (void) correlateLastSavedWrapperExceptionToReport:(NSArray<MSPLCrashReport*> *)reports;
+ (void) deleteWrapperExceptionWithUUID:(NSString *)uuid;
+ (void) deleteWrapperExceptionWithUUIDRef:(CFUUIDRef)uuidRef;
+ (MSWrapperException *) loadWrapperExceptionWithUUIDRef:(CFUUIDRef)uuidRef;
@end
