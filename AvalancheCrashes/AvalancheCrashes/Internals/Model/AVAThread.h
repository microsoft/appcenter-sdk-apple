/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 *
 * OpenAPI spec version: 1.0.0-preview20160708
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
