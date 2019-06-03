// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents token data entity.
 */
@interface MSAuthTokenInfo : NSObject <NSCoding>

/**
 * Account Id string.
 */
@property(nonatomic, nullable, copy, readonly) NSString *accountId;

/**
 * Auth token string.
 */
@property(nonatomic, nullable, copy, readonly) NSString *authToken;

/**
 * Time and date from which the token began to act.
 * It can be nil if it applies to all logs before endTime.
 */
@property(nonatomic, nullable, readonly) NSDate *startTime;

/**
 * Used to store expiration time of token.
 * Nil for valid tokens with unknown or not pre-defined expiration time.
 */
@property(nonatomic, nullable, readonly) NSDate *expiresOn;

/**
 * Initialize a token info with required parameters.
 *
 * @param authToken Auth token.
 * @param accountId Account Id.
 * @param startTime Start time.
 * @param expiresOn End time.
 *
 * @return Token info instance.
 */
- (instancetype)initWithAuthToken:(nullable NSString *)authToken
                        accountId:(nullable NSString *)accountId
                        startTime:(nullable NSDate *)startTime
                        expiresOn:(nullable NSDate *)expiresOn;

@end

NS_ASSUME_NONNULL_END
