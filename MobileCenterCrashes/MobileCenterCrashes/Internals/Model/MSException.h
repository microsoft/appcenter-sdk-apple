/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MobileCenter+Internal.h"
#import <Foundation/Foundation.h>

@class MSStackFrame;

@interface MSException : NSObject <MSSerializableObject>

/*
 * Exception type.
 */
@property(nonatomic, nonnull) NSString *type;

/*
 * Exception reason.
 */
@property(nonatomic, nonnull) NSString *message;

/*
 * Stack frames [optional].
 */
@property(nonatomic, nullable) NSArray<MSStackFrame *> *frames;

/*
 * Inner exceptions of this exception [optional].
 */
@property(nonatomic, nullable) NSArray<MSException *> *innerExceptions;

/*
 * Name of the wrapper SDK that emitted this exeption.
 * Consists of the name of the SDK and the wrapper platform, e.g. "mobilecenter.xamarin", "hockeysdk.cordova".
 */
@property(nonatomic, nullable) NSString *wrapperSdkName;

/**
 * Is equal to another exception
 *
 * @param exception Exception
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:(nullable MSException *)exception;

@end
