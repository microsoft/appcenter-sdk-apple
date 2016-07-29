/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVASender.h"
#import "AVASenderCall.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAHttpSender : NSObject <AVASender>

/**
 *	Send Url
 */
@property(nonatomic, strong, readonly) NSURL *sendURL;

/**
 *	Request header parameters
 */
@property(nonatomic, strong) NSDictionary *httpHeaders;

/**
 *  Pending http calls
 */
@property(atomic, strong) NSMutableDictionary<NSString *, AVASenderCall *> *pendingCalls;

/**
 *  Reachability library
 */
@property(nonatomic) AVA_Reachability *reachability;

@end
NS_ASSUME_NONNULL_END