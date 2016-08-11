/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>

@interface AVAAbstractErrorLog : AVALogWithProperties

/*
 * Error identifier.
 */
@property(nonatomic) NSString *errorId;

/*
 * Process identifier.
 */
@property(nonatomic) NSNumber *processId;

/*
 * Process name.
 */
@property(nonatomic) NSString *processName;

/*
 * Parent's process identifier. [optional]
 */
@property(nonatomic) NSNumber *parentProcessId;

/*
 * Parent's process name. [optional]
 */
@property(nonatomic) NSString *parentProcessName;

/*
 * Error thread identifier. [optional]
 */
@property(nonatomic) NSNumber *errorThreadId;

/*
 * Error thread name. [optional]
 */
@property(nonatomic) NSString *errorThreadName;

/*
 * If true, this error report is an application crash.
 */
@property(nonatomic) NSNumber *fatal;

/*
 * Corresponds to the number of milliseconds elapsed between the time the error occurred and the app was launched.
 */
@property(nonatomic) NSNumber *appLaunchTOffset;

- (instancetype)initWithCoder:(NSCoder *)coder;

- (void)encodeWithCoder:(NSCoder *)coder;

@end
