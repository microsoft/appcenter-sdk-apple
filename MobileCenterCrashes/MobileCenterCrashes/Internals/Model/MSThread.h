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
@property(nonatomic, nonnull) NSNumber *threadId;

/*
 * Thread name. [optional]
 */
@property(nonatomic, copy, nullable) NSString *name;

/*
 * Stack frames.
 */
@property(nonatomic, nonnull) NSMutableArray<MSStackFrame *> *frames;

/*
 * The last exception backtrace.
 */
@property(nonatomic, nonnull) MSException *exception;

/**
 * Is equal to another thread
 *
 * @param thread Thread
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:( MSThread * _Nonnull )thread;

/**
 * Checks if the object's values are valid.
 *
 * return YES, if the object is valid
 */
- (BOOL)isValid;

@end
