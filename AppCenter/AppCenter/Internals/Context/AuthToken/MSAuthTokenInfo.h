// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSAuthTokenInfo : NSObject

@property(nonatomic, nullable, copy, readonly) NSString *authToken;

@property(nonatomic, readonly) int timestamp;

- (instancetype)initWithAuthToken:(nullable NSString *)authToken
                     andTimestamp:(int)timestamp;

@end

NS_ASSUME_NONNULL_END
