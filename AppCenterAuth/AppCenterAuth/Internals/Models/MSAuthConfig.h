// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAuthority.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAuthConfig : NSObject

/**
 * The auth scope to be used for user authentication.
 */
@property(nonatomic, copy) NSString *authScope;

/**
 * The client ID (aka application ID) of Azure AD B2C application.
 */
@property(nonatomic, copy) NSString *clientId;

/**
 * The redirect URI to get back to an application after authentication.
 */
@property(nonatomic, copy) NSString *redirectUri;

/**
 * The authorities that contain URLs for user flows.
 */
@property(nonatomic, copy) NSArray<MSAuthority *> *authorities;

/**
 * Initialize an object from dictionary.
 *
 * @param dictionary A dictionary that contains key/value pairs for a config.
 *
 * @return A new instance.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

/**
 * Checks if the object's values are valid.
 *
 * @return YES, if the object is valid.
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END
