// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents token data entity.
 */
@interface MSAuthTokenInfo : NSObject <NSCoding>

/**
 * Auth token string.
 */
@property(nonatomic, nullable, copy, readonly) NSString *authToken;

/**
 * Time and date from which the token began to act.
 */
@property(nonatomic, nullable, readonly) NSDate *startTime;

/**
 * Time and date to which token acted.
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
- (instancetype)initWithAuthToken:(nullable NSString *)authToken
                     andStartTime:(nullable NSDate *)startTime
                       andEndTime:(nullable NSDate *)endTime;

@end

NS_ASSUME_NONNULL_END
