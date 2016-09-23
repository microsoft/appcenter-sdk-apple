/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SonomaCore+Internal.h"
#import <Foundation/Foundation.h>

@class SNMStackFrame;
@class SNMException;

@interface SNMThread : NSObject <SNMSerializableObject>

/*
 * Thread identifier.
 */
@property(nonatomic) NSNumber *threadId;

/*
 * Thread name. [optional]
 */
@property(nonatomic) NSString *name;

/*
 * Stack frames.
 */
@property(nonatomic) NSMutableArray<SNMStackFrame *> *frames;

/*
 * The last exception backtrace.
 */
@property(nonatomic) SNMException *exception;

/**
 * Is equal to another thread
 *
 * @param thread Thread
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:(SNMThread *)thread;

@end
