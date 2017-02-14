/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSServiceAbstract.h"
#import "MSSender.h"

@interface MSUpdates : MSServiceAbstract

/**
 * A sender instance that is used to send update request to the backend.
 */
@property(nonatomic) id<MSSender> sender;

/**
 * Change the base URL that is used to  login/authenticate users.
 *
 * @param loginUrl The URL that will be used for login.
 */
+ (void)setLoginUrl:(NSString *)loginUrl;

/**
 * Change the base URL that is used to fetch updates.
 *
 * @param updateUrl The URL will be used to fetch updates.
 */
+ (void)setUpdateUrl:(NSString *)updateUrl;

@end
