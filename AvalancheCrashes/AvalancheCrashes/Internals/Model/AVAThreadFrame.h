/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>

@interface AVAThreadFrame : NSObject <AVASerializableObject>

/* Frame address [optional].
 */
@property(nonatomic) NSString *address;

/* Frame symbol [optional].
 */
@property(nonatomic) NSString *symbol;

/* Registers [optional].
 */
@property(nonatomic) NSDictionary<NSString *, NSString *> *registers;

@end
