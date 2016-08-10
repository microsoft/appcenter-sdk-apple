/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AvalancheHub+Internal.h"

@interface AVABinary : NSObject <AVASerializableObject>

@property(nonatomic) NSString* binaryId;

@property(nonatomic) NSString* startAddress;

@property(nonatomic) NSString* endAddress;

@property(nonatomic) NSString* name;

/* amd64, arm64, x86...
 */
@property(nonatomic) NSString* architecture;

@property(nonatomic) NSString* path;

@end
