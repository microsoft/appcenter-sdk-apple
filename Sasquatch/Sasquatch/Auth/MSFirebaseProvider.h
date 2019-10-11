// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@protocol AuthProviderDelegate;
@protocol FUIAuthDelegate;
@class MSUserInformation;
@class FUIAuth;

typedef void (^MSCompletionHandler)(MSUserInformation *userInformation, NSError *error);

@interface MSFirebaseProvider : NSObject <AuthProviderDelegate, FUIAuthDelegate>

@property FUIAuth *auth;

@property MSCompletionHandler completionHandler;

@end
