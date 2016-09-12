/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMSender.h"
#import "SNMSenderCall.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SNMHttpSender : NSObject <SNMSender>

/**
 *	Send Url.
 */
@property(nonatomic, strong, readonly) NSURL *sendURL;

/**
 *	Request header parameters.
 */
@property(nonatomic, strong) NSDictionary *httpHeaders;

/**
 *  Pending http calls.
 */
@property(atomic, strong) NSMutableDictionary<NSString *, id<SNMSenderCall>> *pendingCalls;

/**
 *  Reachability library.
 */
@property(nonatomic) SNM_Reachability *reachability;

@end
NS_ASSUME_NONNULL_END
