#import <Foundation/Foundation.h>

@class MSException;

/**
 * This class represents a wrapper exception that augments the data recorded when the application crashes.
 */
@interface MSWrapperException : NSObject

/**
 * The model exception for the corresponding crash.
 */
@property(nonatomic) MSException *modelException;

/**
 * Additional data that the wrapper SDK needs to save.
 */
@property(nonatomic) NSData *exceptionData;

/**
 * Id of the crashed process; used for correlation to a PLCrashReport.
 */
@property(nonatomic, copy) NSNumber *processId;

@end
