/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SonomaCore+Internal.h"
#import <Foundation/Foundation.h>
#import "SNMAbstractErrorLog.h"

@class SNMThread, SNMBinary;

/*
 * Error log for Apple platforms.
 */
@interface SNMAppleErrorLog : SNMAbstractErrorLog

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
@property(nonatomic, nullable) NSArray<SNMThread *> *threads;

/*
 * Binaries associated to the error [optional].
 */
@property(nonatomic, nullable) NSArray<SNMBinary *> *binaries;

/*
 * Registers. [optional]
 */
@property(nonatomic, nullable) NSDictionary<NSString *, NSString *> *registers;





@end
