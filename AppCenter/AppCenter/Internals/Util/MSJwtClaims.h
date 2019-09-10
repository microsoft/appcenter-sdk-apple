// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSJwtClaims : NSObject

/*
 * The JWT subject.
 */
@property(nonatomic, copy, readonly) NSString *subject;

/*
 * The JWT expiration date.
 */
@property(nonatomic, copy, readonly) NSDate *expirationDate;

/*
 * Parses the JWT.
 *
 * @param jwt The jwt string.
 *
 * @return MSJwtCLaims instance if the string is a valid JWT.
 */
+ (MSJwtClaims *)parse:(NSString *)jwt;

/*
 * Returns the subject.
 *
 * @return NSString The subject.
 */
- (NSString *)getSubject;

/*
 * Returns the expiration date.
 *
 * @return NSDate The expiration date.
 */
- (NSDate *)getExpirationDate;

/*
 * Initializes the MSJwtClaims with the subject and expiration
 *
 * @param subject The JWT subject.
 * @param expirationDate the JWT expiration date.
 *
 * @return MSJwtClaims instance.
 */
- (instancetype)initWithSubject:(NSString *)subject expirationDate:(NSDate *)expirationDate;

@end
