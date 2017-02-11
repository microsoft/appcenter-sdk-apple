/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSServiceAbstract.h"

@interface MSUpdates : MSServiceAbstract

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
