/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AvalancheHub+Internal.h"

@interface AVABinary : NSObject <AVASerializableObject>

/**
 * The binary id.
 */
@property(nonatomic) NSString* binaryId;

/**
 * The binary's start address.
 */
@property(nonatomic) NSString* startAddress;

/**
 * The binary's end address.
 */
@property(nonatomic) NSString* endAddress;

/**
 * The binary's name.
 */
@property(nonatomic) NSString* name;

/**
 * The binary's architecture.
 */
@property(nonatomic) NSString* architecture;

/**
 * The path to the binary.
 */
@property(nonatomic) NSString* path;

@end
