// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MSUserIdContext;

@protocol MSUserIdContextDelegate <NSObject>

@optional

- (void)onNewUserId:(MSUserIdContext *)userId;

@end

NS_ASSUME_NONNULL_END
