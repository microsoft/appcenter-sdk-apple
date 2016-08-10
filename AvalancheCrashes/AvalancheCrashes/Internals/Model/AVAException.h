/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AvalancheHub+Internal.h"

@class AVAThreadFrame;

@interface AVAException : NSObject <AVASerializableObject>

/* number of the exception [optional]
 */
@property(nonatomic) NSNumber* exceptionId;

/* reason string of the exception [optional].
 */
@property(nonatomic) NSString* reason;

/**
 * The thread frame's language.
 */
@property(nonatomic) NSString* language;

/* Exception stack trace frames [optional].
 */
@property(nonatomic) NSArray<AVAThreadFrame *>* frames;

/* Inner exceptions [optional].
 */
@property(nonatomic) NSArray<AVAException *>* innerExceptions;

@end
