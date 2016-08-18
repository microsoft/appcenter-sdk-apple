/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>

@class AVAThreadFrame;

@interface AVAAppleException : NSObject <AVASerializableObject>

/* Exception type.
 */
@property(nonatomic) NSString* type;

/* reason string of the exception.
 */
@property(nonatomic) NSString *reason;


/* Exception stack trace frames [optional].
 */
@property(nonatomic) NSArray<AVAThreadFrame *> *frames;

@end
