/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAChannelDelegate.h"
#import "AVASender.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAHttpSender : NSObject <AVASender>

@property(nonatomic, weak) id<AVAChannelDelegate> delegate;

/**
 *	BaseURL to which relative paths are appended.
 */
@property(nonatomic, strong, readonly) NSString *baseURL;

/**
 *	Request header parameters.
 */
@property(nonatomic, strong) NSDictionary *headerParam;

// Methods
+ (BOOL)isRecoverableError:(NSURLResponse *)response;

@end
NS_ASSUME_NONNULL_END