#import <Foundation/Foundation.h>

@class MSException;

/**
 * This is required for Wrapper SDKs that need to install their own
 * signal handlers for certain signals.
 */
@protocol MSWrapperCrashesInitializationDelegate <NSObject>

/**
 * Implement this function to override the default behavior for
 * setting up the crash handlers (i.e., configuring PLCrashReporter)
 */
@optional
- (BOOL) setUpCrashHandlers;

@end

@interface MSWrapperExceptionManager : NSObject

/**
 * Check if a wrapper SDK has stored an exception in memory.
 *
 * @return YES if there is an exception from a wrapper SDK
 */
+ (BOOL)hasException;

/**
 * Load an MSException from a wrapper SDK into memory
 *
 * @param uuidRef The UUID of the associated incident
 * @return The wrapper exception corresponding to uuidRef
 */
+ (MSException*)loadWrapperException:(CFUUIDRef)uuidRef;

/**
 * Save the wrapper exception in memory to disk
 *
 * @param uuidRef The UUID of the associated incident
 */
+ (void)saveWrapperException:(CFUUIDRef)uuidRef;

/**
 * Remove the wrapper exception corresponding to uuidRef from disk
 *
 * @param uuidRef The UUID of the associated incident
 */
+ (void)deleteWrapperExceptionWithUUID:(CFUUIDRef)uuidRef;

/**
 * Remove all saved wrapper exception files from disk.
 */
+ (void)deleteAllWrapperExceptions;

/**
 * Save a wrapper exception in memory. This should only be used by
 * a wrapper SDK.
 *
 * @param exception The exception to be stored
 */
+ (void)setWrapperException:(MSException*)exception;

/**
 * Save (in memory) any additional data that a wrapper SDK needs to
 * generate an error report. This should only be used by a wrapper
 * SDK.
 *
 * @param data The exception data to be stored
 */
+ (void)setWrapperExceptionData:(NSData*)data;

/**
 * Load exception data from a wrapper SDK into memory.
 *
 * @param uuidString String representation of the UUID of the incident
 * @return The wrapper exception data corresponding to uuidString
 */
+ (NSData*)loadWrapperExceptionDataWithUUIDString:(NSString*)uuidString;

/**
 * Delete a particular wrapper exception data file from disk and store it
 * in memory
 *
 * @param uuidString String representation of the UUID of the incident
 */
+ (void)deleteWrapperExceptionDataWithUUIDString:(NSString*)uuidString;

/**
 * Remove all saved wrapper exception data files from disk.
 */
+ (void)deleteAllWrapperExceptionData;

/**
 * Configure the crash reporting libraries. This should only be used in the delegate method
 * for MSWrapperCrashesInitializationDelegate, and only by a wrapper SDK.
 */
+ (void)startCrashReportingFromWrapperSdk;

/**
 * Set a delegate for intercepting the point at which the crash libraries are 
 * set up. This should only be used by a wrapper SDK.
 */
+ (void)setDelegate:(id<MSWrapperCrashesInitializationDelegate>) delegate;

/**
 * Get the previously set delegate for intercepting the point at which the crash libraries
 * are set up.
 */
+ (id<MSWrapperCrashesInitializationDelegate>)getDelegate;

+ (void)trackWrapperException:(MSException*)exception withData:(NSData*)data fatal:(BOOL)fatal;
@end
