/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVASender.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAHttpSender : NSObject <AVASender>

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