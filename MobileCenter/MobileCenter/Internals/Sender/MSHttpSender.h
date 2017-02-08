/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSSender.h"
#import "MSSenderCall.h"

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface MSHttpSender : NSObject <MSSender>

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
@property(atomic, strong) NSMutableDictionary<NSString *, id <MSSenderCall>> *pendingCalls;

@end

NS_ASSUME_NONNULL_END
