#import "MobileCenter+Internal.h"
#import <Foundation/Foundation.h>

@class MSErrorAttachment;

@interface MSAbstractErrorLog : MSLogWithProperties

/*
 * Error identifier.
 */
@property(nonatomic,copy, nonnull) NSString *errorId;

/*
 * Process identifier.
 */
@property(nonatomic, nonnull) NSNumber *processId;

/*
 * Process name.
 */
@property(nonatomic, copy, nonnull) NSString *processName;

/*
 * Parent's process identifier. [optional]
 */
@property(nonatomic, nullable) NSNumber *parentProcessId;

/*
 * Name of the parent's process. [optional]
 */
@property(nonatomic, copy, nullable) NSString *parentProcessName;

/*
 * Error thread identifier. [optional]
 */
@property(nonatomic, nullable) NSNumber *errorThreadId;

/*
 * Error thread name. [optional]
 */
@property(nonatomic, copy, nullable) NSString *errorThreadName;

/*
 * If YES, this error report is an application crash.
 */
@property(nonatomic) BOOL fatal;

/*
 * Corresponds to the number of milliseconds elapsed between the time the error occurred and the app was launched.
 */
@property(nonatomic, nonnull) NSNumber *appLaunchTOffset;

/*
 * Error attachment. [optional]
 */
@property(nonatomic, nullable) MSErrorAttachment *errorAttachment;

/*
 * CPU Architecture. [optional]
 */
@property(nonatomic, copy, nullable) NSString *architecture;

@end
