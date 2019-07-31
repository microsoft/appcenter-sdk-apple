// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAnalyticsAuthenticationProvider.h"

@interface MSAnalyticsAuthenticationProvider ()

@property(nonatomic, assign) signed char isAlreadyAcquiringToken;

@property(nonatomic, strong) NSDate *expiryDate;

/**
 * Request a new token from the app.
 */
- (void)acquireTokenAsync;

@end
