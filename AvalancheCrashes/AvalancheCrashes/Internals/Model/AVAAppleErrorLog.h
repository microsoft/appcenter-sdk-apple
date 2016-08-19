/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>

@class AVAAppleThread, AVAAppleBinary, AVAAppleException;

@interface AVAAppleErrorLog : AVALogWithProperties

/*
 * Crash identifier.
 */
@property(nonatomic) NSString *errorId;

/*
 * Process identifier. [optional]
 */
@property(nonatomic) NSNumber *processId;

/*
 * Name of the process that crashes. [optional]
 */
@property(nonatomic) NSString *processName;

/*
 * Parent's process identifier. [optional]
 */
@property(nonatomic) NSNumber *parentProcessId;

/*
 * Name of the parent's process. [optional]
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
@property(nonatomic) BOOL fatal;

/*
 * Corresponds to the number of milliseconds elapsed between the time the app
 * was launched and the log was sent. [optional]
 */
@property(nonatomic) NSNumber *appLaunchTOffset;

/*
 * CPU type.
 */
@property(nonatomic) NSNumber *cpuType;

/*
 * CPU sub type. [optional]
 */
@property(nonatomic) NSNumber *cpuSubType;

/*
 * Path to the application.
 */
@property(nonatomic) NSString *applicationPath;

/*
 * OS exception type.
 */
@property(nonatomic) NSString *osExceptionType;

/*
 * OS exception code.
 */
@property(nonatomic) NSString *osExceptionCode;

/*
 * OS exception address.
 */
@property(nonatomic) NSString *osExceptionAddress;

/*
 * Exception type. [optional]
 */
@property(nonatomic) NSString *exceptionType;

/*
 * Exception reason. [optional]
 */
@property(nonatomic) NSString *exceptionReason;

/*
 * Registers. [optional]
 */
@property(nonatomic) NSDictionary<NSString *, NSString *> *registers;

/*
 * Thread stacktraces associated to the crash. [optional]
 */
@property(nonatomic) NSArray<AVAAppleThread *> *threads;

/*
 * Binaries associated to the crash with their associated addresses (used only
 * on iOS to symbolicate the stacktrace). [optional]
 */
@property(nonatomic) NSArray<AVAAppleBinary *> *binaries;

@end
