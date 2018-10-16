#import <Foundation/Foundation.h>

#import "AppCenter+Internal.h"

@class MSException;
@class MSStackFrame;

@interface MSThread : NSObject <MSSerializableObject>

/**
 * Thread identifier.
 */
@property(nonatomic) NSNumber *threadId;

/**
 * Thread name. [optional]
 */
@property(nonatomic, copy) NSString *name;

/**
 * Stack frames.
 */
@property(nonatomic) NSMutableArray<MSStackFrame *> *frames;

/**
 * The last exception backtrace.
 */
@property(nonatomic) MSException *exception;

/**
 * Checks if the object's values are valid.
 *
 * @return YES, if the object is valid.
 */
- (BOOL)isValid;

@end
