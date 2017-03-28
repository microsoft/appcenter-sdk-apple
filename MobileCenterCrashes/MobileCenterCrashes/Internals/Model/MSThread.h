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
@property(nonatomic, copy) NSString *name;

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
 * @param object Thread
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:(id)object;

/**
 * Checks if the object's values are valid.
 *
 * return YES, if the object is valid
 */
- (BOOL)isValid;

@end
