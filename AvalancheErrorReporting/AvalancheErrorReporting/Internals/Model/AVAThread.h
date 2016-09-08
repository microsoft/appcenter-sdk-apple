/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>

@class AVAStackFrame;
@class AVAException;

@interface AVAThread : NSObject <AVASerializableObject>

/*
 * Thread identifier.
 */
@property(nonatomic) NSNumber *threadId;

/*
 * Thread name. [optional]
 */
@property(nonatomic) NSString* name;

/*
 * Stack frames.
 */
@property(nonatomic) NSMutableArray<AVAStackFrame *> *frames;

/*
 * The last exception backtrace.
 */
@property(nonatomic) AVAException* exception;


@end
