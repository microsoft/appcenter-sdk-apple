// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

NS_ASSUME_NONNULL_BEGIN

@class MSAuthTokenInfo;
@class MSEncrypter;

@interface MSAuthTokenContext ()

/**
 * Collection of channel delegates.
 */
@property(nonatomic) NSHashTable<id<MSAuthTokenContextDelegate>> *delegates;

/**
 * YES if the current token should be reset.
 */
@property(nonatomic, getter=isResetAuthTokenRequired) BOOL resetAuthTokenRequired;

/*
 * Encrypter for target tokens.
 */
@property(nonatomic) MSEncrypter *encrypter;

/**
 * Private field used to get and set auth tokens history array.
 */
@property(nullable, nonatomic) NSArray<MSAuthTokenInfo *> *authTokenHistoryArray;

/**
 * Reset singleton instance.
 */
+ (void)resetSharedInstance;

/**
 * Gets auth token history array.
 */
- (NSArray<MSAuthTokenInfo *> *)authTokenHistory;

/**
 * Sets auth token history array.
 */
- (void)setAuthTokenHistory:(nullable NSArray<MSAuthTokenInfo *> *)authTokenHistory;

@end

NS_ASSUME_NONNULL_END
