// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents token data entity.
 */
@interface MSAuthTokenValidityInfo : NSObject

/**
 * Auth token string.
 */
@property(nonatomic, nullable, readonly) NSString *authToken;

/**
 * Time and date from which the token began to act.
 * It can be nil if it applies to all logs before endTime.
 */
@property(nonatomic, nullable, readonly) NSDate *startTime;

/**
 * Time and date to which token acted.
 * It can be nil if it's still valid.
 * In the keychain encoded data used to store expiration time.
 */
@property(nonatomic, nullable, readonly) NSDate *endTime;

/**
 * Initialize a token info with required parameters.
 *
 * @param authToken Auth token.
 * @param startTime Start time.
 * @param endTime End time.
 *
 * @return Token info instance.
 */
- (instancetype)initWithAuthToken:(nullable NSString *)authToken startTime:(nullable NSDate *)startTime endTime:(nullable NSDate *)endTime;

/**
 * Indicates whether this token expires soon.
 * @see kMSSecBeforeExpireToRefresh.
 *
 * @return YES if token expires soon and needs to be refreshed, NO otherwise.
 */
- (BOOL)expiresSoon;

@end

NS_ASSUME_NONNULL_END
