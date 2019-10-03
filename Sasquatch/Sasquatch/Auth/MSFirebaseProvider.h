// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "Sasquatch-Swift.h"

@import FirebaseAuthUI;

typedef void (^MSCompletionHandler)(MSUserInformation *userInformation, NSError *error);

@interface MSFirebaseProvider : NSObject <AuthProviderDelegate, FUIAuthDelegate>

@property FUIAuth *auth;

@property MSCompletionHandler completionHandler;

@end
