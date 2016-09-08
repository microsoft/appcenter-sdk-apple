/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>
#import "AVAAbstractErrorLog.h"

@class AVAThread, AVABinary;

/*
 * Error log for Apple platforms.
 */
@interface AVAAppleErrorLog : AVAAbstractErrorLog

/*
 * CPU primary architecture.
 */
@property(nonatomic, nonnull) NSNumber *primaryArchitectureId;

/*
 * CPU architecture variant [optional].
 */
@property(nonatomic, nullable) NSNumber *architectureVariantId;

/*
 * Path to the application.
 */
@property(nonatomic, nonnull) NSString *applicationPath;

/*
 * OS exception type.
 */
@property(nonatomic, nonnull) NSString *osExceptionType;

/*
 * OS exception code.
 */
@property(nonatomic, nonnull) NSString *osExceptionCode;

/*
 * OS exception address.
 */
@property(nonatomic, nonnull) NSString *osExceptionAddress;

/*
 * Exception type [optional].
 */
@property(nonatomic, nullable) NSString *exceptionType;

/*
 * Exception reason [optional].
 */
@property(nonatomic, nullable) NSString *exceptionReason;

/*
 * Thread stack frames associated to the error [optional].
 */
@property(nonatomic, nullable) NSArray<AVAThread *> *threads;

/*
 * Binaries associated to the error [optional].
 */
@property(nonatomic, nullable) NSArray<AVABinary *> *binaries;

/*
 * Registers. [optional]
 */
@property(nonatomic, nullable) NSDictionary<NSString *, NSString *> *registers;





@end
