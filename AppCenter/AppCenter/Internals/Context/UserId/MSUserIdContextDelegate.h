// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

NS_ASSUME_NONNULL_BEGIN

@class MSUserIdContext;

@protocol MSUserIdContextDelegate <NSObject>

/**
 * A callback that is called after a new userId is set.
 *
 * @param userIdContext userId context.
 * @param userId userId which was set.
 */
- (void)userIdContext:(MSUserIdContext *)userIdContext didUpdateUserId:(nullable NSString *)userId;

@end

NS_ASSUME_NONNULL_END
