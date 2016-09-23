/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SonomaCore+Internal.h"
#import <Foundation/Foundation.h>

@class SNMErrorAttachment;

@interface SNMAbstractErrorLog : SNMLogWithProperties

/*
 * Error identifier.
 */
@property(nonatomic, nonnull) NSString *errorId;

/*
 * Process identifier.
 */
@property(nonatomic, nonnull) NSNumber *processId;

/*
 * Process name.
 */
@property(nonatomic, nonnull) NSString *processName;

/*
 * Parent's process identifier. [optional]
 */
@property(nonatomic, nullable) NSNumber *parentProcessId;

/*
 * Name of the parent's process. [optional]
 */
@property(nonatomic, nullable) NSString *parentProcessName;

/*
 * Error thread identifier. [optional]
 */
@property(nonatomic, nullable) NSNumber *errorThreadId;

/*
 * Error thread name. [optional]
 */
@property(nonatomic, nullable) NSString *errorThreadName;

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
@property(nonatomic, nullable) SNMErrorAttachment *errorAttachment;

/*
 * CPU Architecture. [optional]
 */
@property(nonatomic, nullable) NSString *architecture;

@end
