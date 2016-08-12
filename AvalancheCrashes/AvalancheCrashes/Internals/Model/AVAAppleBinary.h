/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>

@interface AVAAppleBinary : NSObject <AVASerializableObject>

/**
 * The binary id.
 */
@property(nonatomic) NSString *binaryId;

/**
 * The binary's start address.
 */
@property(nonatomic) NSString *startAddress;

/**
 * The binary's end address.
 */
@property(nonatomic) NSString *endAddress;

/**
 * The binary's name.
 */
@property(nonatomic) NSString *name;

/**
 * The path to the binary.
 */
@property(nonatomic) NSString *path;

/**
 * The binary's cpuType.
 */
@property(nonatomic) NSNumber *cpuType;

/**
 * The binary's cpuSubType.
 */
@property(nonatomic) NSNumber *cpuSubType;


@end
