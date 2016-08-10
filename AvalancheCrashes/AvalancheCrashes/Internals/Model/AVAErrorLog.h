/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>

@class AVAThread, AVABinary, AVAException;

@interface AVAErrorLog : AVALogWithProperties

/* Crash identifier.
 */
@property(nonatomic) NSString *crashId;

/* Name of the process that crashes. [optional]
 */
@property(nonatomic) NSString *process;

/* Process identifier. [optional]
 */
@property(nonatomic) NSNumber *processId;

/* Name of the parent's process. [optional]
 */
@property(nonatomic) NSString *parentProcess;

/* Parent's process identifier. [optional]
 */
@property(nonatomic) NSNumber *parentProcessId;

/* Id of the thread that crashes. [optional]
 */
@property(nonatomic) NSNumber *crashThread;

/* Path to the application. [optional]
 */
@property(nonatomic) NSString *applicationPath;

/* Corresponds to the number of milliseconds elapsed between the time the app
 * was launched and the log was sent. [optional]
 */
@property(nonatomic) NSNumber *appLaunchTOffset;

/* Exception type.
 */
@property(nonatomic) NSString *exceptionType;

/* Exception code. [optional]
 */
@property(nonatomic) NSString *exceptionCode;

/* Exception address. [optional]
 */
@property(nonatomic) NSString *exceptionAddress;

/* Exception reason.
 */
@property(nonatomic) NSString *exceptionReason;
/* Crash or handled exception
 */
@property(nonatomic) NSNumber *fatal;

/* Thread stacktraces associated to the crash. [optional]
 */
@property(nonatomic) NSArray<AVAThread *> *threads;

/* Exception stacktraces associated to the crash. [optional]
 */
@property(nonatomic) NSArray<AVAException *> *exceptions;

/* Binaries associated to the crash with their associated addresses (used only
 * on iOS to symbolicate the stacktrace). [optional]
 */
@property(nonatomic) NSArray<AVABinary *> *binaries;

@end
