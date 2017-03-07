#import "MobileCenter+Internal.h"
#import <Foundation/Foundation.h>

@class MSErrorAttachment;

@interface MSAbstractErrorLog : MSLogWithProperties

/*
 * Error identifier.
 */
@property(nonatomic,copy) NSString *errorId;

/*
 * Process identifier.
 */
@property(nonatomic) NSNumber *processId;

/*
 * Process name.
 */
@property(nonatomic, copy) NSString *processName;

/*
 * Parent's process identifier. [optional]
 */
@property(nonatomic) NSNumber *parentProcessId;

/*
 * Name of the parent's process. [optional]
 */
@property(nonatomic, copy) NSString *parentProcessName;

/*
 * Error thread identifier. [optional]
 */
@property(nonatomic) NSNumber *errorThreadId;

/*
 * Error thread name. [optional]
 */
@property(nonatomic, copy) NSString *errorThreadName;

/*
 * If YES, this error report is an application crash.
 */
@property(nonatomic) BOOL fatal;

/*
 * Corresponds to the number of milliseconds elapsed between the time the error occurred and the app was launched.
 */
@property(nonatomic) NSNumber *appLaunchTOffset;

/*
 * Error attachment. [optional]
 */
@property(nonatomic) MSErrorAttachment *errorAttachment;

/*
 * CPU Architecture. [optional]
 */
@property(nonatomic, copy) NSString *architecture;

@end
