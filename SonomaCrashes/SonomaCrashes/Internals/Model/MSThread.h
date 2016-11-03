/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MobileCenter+Internal.h"
#import <Foundation/Foundation.h>

@class MSStackFrame;
@class MSException;

@interface MSThread : NSObject <MSSerializableObject>

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
@property(nonatomic) NSMutableArray<MSStackFrame *> *frames;

/*
 * The last exception backtrace.
 */
@property(nonatomic) MSException *exception;

/**
 * Is equal to another thread
 *
 * @param thread Thread
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:(MSThread *)thread;

@end
