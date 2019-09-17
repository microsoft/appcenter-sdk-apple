// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSJwtClaims : NSObject

/**
 * The JWT subject.
 */
@property(nonatomic, copy, readonly) NSString *subject;

/**
 * The JWT expiration.
 */
@property(nonatomic, copy, readonly) NSDate *expiration;

/**
 * Parses the JWT.
 *
 * @param jwt The JWT string.
 *
 * @return MSJwtCLaims instance if the string is a valid JWT. If the `exp` claim is invalid, then we
 * return the instance with an expiration time of 0. Otherwise, we return `nil`.
 *
 * @discussion Our behavior differs from Android here because it is difficult to determine the type of the
 * exp claim. For JWTs with invalid `exp` claims, the parsing interprets `nil` as 0. In Android, we return
 * `nil` if the type of the `exp` claim is invalid.
 */
+ (MSJwtClaims *)parse:(NSString *)jwt;

/**
 * Initializes the MSJwtClaims with the subject and expiration
 *
 * @param subject The JWT subject.
 * @param expiration the JWT expiration date expressed as seconds since 1970.
 *
 * @return MSJwtClaims instance.
 */
- (instancetype)initWithSubject:(NSString *)subject expiration:(NSDate *)expiration;

@end
