/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MobileCenter+Internal.h"

@import Foundation;

/*
 * Binary (library) definition for any platform.
 */
@interface MSBinary : NSObject <MSSerializableObject>

/**
 * The binary id as UUID string.
 */
@property(nonatomic, copy, nonnull) NSString *binaryId;

/**
 * The binary's start address.
 */
@property(nonatomic, copy, nonnull) NSString *startAddress;

/**
 * The binary's end address.
 */
@property(nonatomic, copy, nonnull) NSString *endAddress;

/**
 * The binary's name.
 */
@property(nonatomic, copy, nonnull) NSString *name;

/**
 * The path to the binary.
 */
@property(nonatomic, copy, nonnull) NSString *path;

/**
 * The architecture.
 */
@property(nonatomic, copy, nonnull) NSString *architecture;

/**
 * CPU primary architecture [optional].
 */
@property(nonatomic, nullable) NSNumber *primaryArchitectureId;

/**
 * CPU architecture variant [optional].
 */
@property(nonatomic, nullable) NSNumber *architectureVariantId;

/**
 * Is equal to another binary
 *
 * @param binary Binary
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:(nullable MSBinary *)binary;

/**
 * Checks if the object's values are valid.
 *
 * return YES, if the object is valid
 */
- (BOOL)isValid;

@end
