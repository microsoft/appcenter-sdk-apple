/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 *
 * OpenAPI spec version: 1.0.0-preview20160708
 */

#import <Foundation/Foundation.h>
#import "AvalancheHub+Internal.h"

@interface AVAThreadFrame : NSObject <AVASerializableObject>

/* Frame address [optional]
 */
@property(nonatomic) NSString* address;
/* Frame symbol [optional]
 */
@property(nonatomic) NSString* symbol;
/* Registers [optional]
 */
@property(nonatomic) NSDictionary<NSString*, NSString*>* registers;

@end
