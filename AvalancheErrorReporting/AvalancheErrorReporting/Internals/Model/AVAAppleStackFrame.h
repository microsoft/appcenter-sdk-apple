/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>

@interface AVAAppleStackFrame : NSObject <AVASerializableObject>

/*
 * Frame address.
 */
@property(nonatomic) NSString *address;

/*
 * Frame symbol.
 */
@property(nonatomic) NSString *symbol;

@end
