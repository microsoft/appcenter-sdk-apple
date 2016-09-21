/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SonomaCore+Internal.h"
#import <Foundation/Foundation.h>

/*
 * Binary (library) definition for any platform.
 */
@interface SNMBinary : NSObject <SNMSerializableObject>

/**
 * The binary id as UUID string.
 */
@property(nonatomic, nonnull) NSString *binaryId;

/**
 * The binary's start address.
 */
@property(nonatomic, nonnull) NSString *startAddress;

/**
 * The binary's end address.
 */
@property(nonatomic, nonnull) NSString *endAddress;

/**
 * The binary's name.
 */
@property(nonatomic, nonnull) NSString *name;

/**
 * The path to the binary.
 */
@property(nonatomic, nonnull) NSString *path;

/**
 * CPU primary architecture [optional].
 */
@property(nonatomic, nullable) NSNumber *primaryArchitectureId;

/**
 * CPU architecture variant [optional].
 */
@property(nonatomic, nullable) NSNumber *architectureVariantId;

@end
