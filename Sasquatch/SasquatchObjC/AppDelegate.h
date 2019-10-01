// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AuthProviderDelegate;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property(strong, nonatomic) UIWindow *window;

@property(nonatomic, nullable) id<AuthProviderDelegate> authProvider;

- (void)requestLocation;

@end

NS_ASSUME_NONNULL_END
