/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AvalancheHub+Internal.h"

@class AVAThreadFrame;

@interface AVAThread : NSObject <AVASerializableObject>

/* Thread number.
 */
@property(nonatomic) NSNumber* threadId;

/* Thread frames.
 */
@property(nonatomic) NSMutableArray<AVAThreadFrame *>* frames;

@end
