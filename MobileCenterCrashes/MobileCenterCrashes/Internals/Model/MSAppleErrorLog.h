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
 * Expected values are as follows:
 * public static primary_i386 = 0x00000007;
 * public static primary_x86_64 = 0x01000007;
 * public static primary_arm = 0x0000000C;
 * public static primary_arm64 = 0x0100000C;
 */
@property(nonatomic, nonnull) NSNumber *primaryArchitectureId;

/*
 * CPU architecture variant [optional].
 *
 * If primary is arm64, the possible variants are
 * public static variant_arm64_1 = 0x00000000;
 * public static variant_arm64_2 = 0x0000000D;
 * public static variant_arm64_3 = 0x00000001;
 *
 * If primary is arm, the possible variants are
 * public static variant_armv6 = 0x00000006;
 * public static variant_armv7 = 0x00000009;
 * public static variant_armv7s = 0x0000000B;
 * public static variant_armv7k = 0x0000000C;
 */
@property(nonatomic, nullable) NSNumber *architectureVariantId;

/*
 * Path to the application.
 */
@property(nonatomic, copy, nonnull) NSString *applicationPath;

/*
 * OS exception type.
 */
@property(nonatomic, copy, nonnull) NSString *osExceptionType;

/*
 * OS exception code.
 */
@property(nonatomic, copy, nonnull) NSString *osExceptionCode;

/*
 * OS exception address.
 */
@property(nonatomic, copy, nonnull) NSString *osExceptionAddress;

/*
 * Exception type [optional].
 */
@property(nonatomic, copy, nullable) NSString *exceptionType;

/*
 * Exception reason [optional].
 */
@property(nonatomic, copy, nullable) NSString *exceptionReason;

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
