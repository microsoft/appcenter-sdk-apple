// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <UIKit/UIKit.h>

@class AuthProviderProtocol;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property(strong, nonatomic) UIWindow *window;
@property(nonatomic) AuthProviderProtocol *authProvider;

- (void)requestLocation;

@end
