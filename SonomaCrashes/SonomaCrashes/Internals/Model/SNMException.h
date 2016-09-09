/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "Sonoma+Internal.h"
#import <Foundation/Foundation.h>

@class SNMStackFrame;

@interface SNMException : NSObject <SNMSerializableObject>

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
@property(nonatomic, nullable) NSArray<SNMStackFrame *> *frames;


/*
 * Inner exceptions of this exception [optional].
 */
@property(nonatomic, nullable) NSArray<SNMException *> *innerExceptions;


@end
