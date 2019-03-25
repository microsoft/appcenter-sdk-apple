// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

static short const kMSMaxCharactersDisplayedForAppSecret = 8;
static NSString *const kMSHidingStringForAppSecret = @"*";

@interface MSHttpUtil : NSObject

/**
 * Indicate if the http response is recoverable.
 *
 * @param statusCode Http status code.
 *
 * @return is recoverable.
 */
+ (BOOL)isRecoverableError:(NSInteger)statusCode;

/**
 * Hide a secret replacing the first N characters by a hiding character.
 *
 * @param secret the secret string.
 *
 * @return secret by hiding some characters.
 */
+ (NSString *)hideSecret:(NSString *)secret;

/**
 * Hide an authentication JWT token.
 *
 * @param token the token string.
 *
 * @return token by hiding some characters.
 */
+ (NSString *)hideAuthToken:(NSString *)token;

@end
