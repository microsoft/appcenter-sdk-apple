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
 *	Send Url
 */
@property(nonatomic, strong, readonly) NSURL *sendURL;

/**
 *	Request header parameters.
 */
@property(nonatomic, strong) NSDictionary *httpHeaders;

// Methods
+ (BOOL)isRecoverableError:(NSURLResponse *)response;

@end
NS_ASSUME_NONNULL_END