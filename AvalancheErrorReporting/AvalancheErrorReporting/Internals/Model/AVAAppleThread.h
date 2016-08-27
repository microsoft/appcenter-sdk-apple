/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>

@class AVAAppleStackFrame;
@class AVAAppleException;

@interface AVAAppleThread : NSObject <AVASerializableObject>

/*
 * Thread identifier.
 */
@property(nonatomic) NSNumber *threadId;

/*
 * Thread name. [optional]
 */
@property(nonatomic) NSString* name;

/*
 * The last exception backtrace.
 */
@property(nonatomic) AVAAppleException* lastException;

/*
 * Stack frames.
 */
@property(nonatomic) NSMutableArray<AVAAppleStackFrame *> *frames;

@end
