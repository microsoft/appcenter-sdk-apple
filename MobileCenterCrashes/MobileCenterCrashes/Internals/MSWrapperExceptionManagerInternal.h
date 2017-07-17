#import "MSWrapperExceptionManager.h"

@class MSWrapperException;
@class MSPLCrashReport;

@interface MSWrapperExceptionManager ()
- (void)deleteAllWrapperExceptions;
- (void) correlateLastSavedWrapperExceptionToBestMatchInReports:(NSArray<MSPLCrashReport*> *)reports;
@end
