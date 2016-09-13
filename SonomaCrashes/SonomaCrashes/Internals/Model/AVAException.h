/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SonomaCore+Internal.h"
#import <Foundation/Foundation.h>

@class AVAStackFrame;

@interface AVAException : NSObject <AVASerializableObject>

/*
 * Exception type.
 */
@property(nonatomic, nonnull) NSString *type;

/*
 * Exception reason.
 */
@property(nonatomic, nonnull) NSString *reason;

/*
 * Stack frames [optional].
 */
@property(nonatomic, nullable) NSArray<AVAStackFrame *> *frames;


/*
 * Inner exceptions of this exception [optional].
 */
@property(nonatomic, nullable) NSArray<AVAException *> *innerExceptions;


@end
