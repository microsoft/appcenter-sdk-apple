/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAbstractErrorLog.h"
#import "MobileCenter+Internal.h"
#import <Foundation/Foundation.h>

@class MSThread, MSBinary, MSException;

/*
 * Error log for Apple platforms.
 */
@interface MSAppleErrorLog : MSAbstractErrorLog

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
@property(nonatomic, nullable) NSArray<MSThread *> *threads;

/*
 * Binaries associated to the error [optional].
 */
@property(nonatomic, nullable) NSArray<MSBinary *> *binaries;

/*
 * Registers. [optional]
 */
@property(nonatomic, nullable) NSDictionary<NSString *, NSString *> *registers;

/*
 * The last exception backtrace.
 */
@property(nonatomic, nullable) MSException *exception;

/**
 * Is equal to another apple error log
 *
 * @param errorLog Apple error log
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:(nullable MSAppleErrorLog *)errorLog;

@end
