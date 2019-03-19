// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSAuthTokenInfo : NSObject

@property(nonatomic, nullable, copy, readonly) NSString *authToken;

@property(nonatomic, nullable, readonly) NSDate *startTime;

@property(nonatomic, nullable, readonly) NSDate *endTime;

- (instancetype)initWithAuthToken:(nullable NSString *)authToken
                     andStartTime:(nullable NSDate *)startTime
                       andEndTime:(nullable NSDate *)endTime;

@end

NS_ASSUME_NONNULL_END
