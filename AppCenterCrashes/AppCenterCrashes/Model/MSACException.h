// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#if __has_include(<AppCenter/MSACSerializableObject.h>)
#import <AppCenter/MSACSerializableObject.h>
#else
#import "MSACSerializableObject.h"
#endif

@class MSACStackFrame;

NS_SWIFT_NAME(ExceptionModel)
@interface MSACException : NSObject <MSACSerializableObject>

/**
 * Creates an instance of exception model.
 *
 * @param exceptionType exception type.
 * @param exceptionMessage exception message.
 *
 * @return A new instance of exception model.
 */
- (instancetype)initWithTypeAndMessage:(NSString *)exceptionType exceptionMessage:(NSString *)exceptionMessage;

/**
 * Creates an instance of exception model.
 *
 * @exception exception.
 *
 * @return A new instance of exception model.
 */
- (instancetype)initWithException:(NSException *)exception;

/**
 * Exception type.
 */
@property(nonatomic, copy) NSString *type;

/**
 * Exception reason.
 */
@property(nonatomic, copy) NSString *message;

/**
 * Raw stack trace. Sent when the frames property is either missing or unreliable.
 */
@property(nonatomic, copy) NSString *stackTrace;

/**
 * Stack frames [optional].
 */
@property(nonatomic) NSArray<MSACStackFrame *> *frames;

/**
 * Convert NSError to MSACException.
 *
 * @param error - NSError object.
 *
 * @return MSACException exception.
 */
+ (MSACException *)convertNSErrorToMSACException:(NSError *)error;

/**
 * Checks if the object's values are valid.
 *
 * @return YES, if the object is valid.
 */
- (BOOL)isValid;

@end
