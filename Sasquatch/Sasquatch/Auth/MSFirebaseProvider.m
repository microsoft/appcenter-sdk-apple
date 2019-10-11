// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

@import FirebaseAuthUI;
@import FirebaseCore;
@import FirebaseFacebookAuthUI;

#import "Sasquatch-Swift.h"
#import "MSFirebaseProvider.h"

@implementation MSFirebaseProvider

- (instancetype)init {
  if ((self = [super init])) {

    // Firebase should be configured before accessing Firebase instances.
    [FIRApp configure];
    _auth = [FUIAuth defaultAuthUI];
    _auth.delegate = self;
    _auth.providers = @ [[FUIFacebookAuth new]];
  }
  return self;
}

- (void)signIn:(void (^_Nonnull)(MSUserInformation *_Nullable, NSError *_Nullable))completionHandler {
  if (self.completionHandler != nil) {
    NSLog(@"SignIn in progress.");
    return;
  }
  self.completionHandler = completionHandler;
  UINavigationController *authViewController = [self.auth authViewController];
  UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
  while (topController.presentedViewController != nil) {
    topController = topController.presentedViewController;
  }
  [topController presentViewController:authViewController animated:YES completion:nil];
}

- (void)signOut {
  NSError *error;
  if (![self.auth signOutWithError:&error]) {
    NSLog(@"SignOut failed: %@", error);
  }
}

- (void)appCenter:(MSAppCenter *)appCenter acquireAuthTokenWithCompletionHandler:(MSAuthTokenCompletionHandler)completionHandler {
  FIRUser *user = [FIRAuth auth].currentUser;
  if (user == nil) {
    NSLog(@"Failed to refresh Firebase token as the user is signed out.");
    completionHandler(nil);
  } else {
    [user getIDTokenWithCompletion:^(NSString *_Nullable token, NSError *_Nullable error) {
      if (error == nil) {
        NSLog(@"Refreshed Firebase token.");
        completionHandler(token);
      } else {
        NSLog(@"Failed to refresh Firebase token.");
        completionHandler(nil);
      }
    }];
  }
}

- (void)authUI:(FUIAuth *)authUI didSignInWithAuthDataResult:(FIRAuthDataResult *)authDataResult error:(NSError *)error {
  if (self.completionHandler == nil) {
    NSLog(@"Coulnd't find associated completionHandler for current sign-in request");
    return;
  }

  MSCompletionHandler completionHandler = self.completionHandler;
  self.completionHandler = nil;
  if (error != nil) {
    NSLog(@"Failed to sign-in Firebase.");
    completionHandler(nil, error);
  } else if (authDataResult != nil) {
    [authDataResult.user getIDTokenWithCompletion:^(NSString *_Nullable token, NSError *_Nullable error) {
      if (error == nil) {
        NSLog(@"Received Firebase token.");
        MSUserInformation *userInformation = [MSUserInformation new];
        userInformation.idToken = token;
        completionHandler(userInformation, nil);
      } else {
        NSLog(@"Failed to get a token for the user.");
        completionHandler(nil, error);
      }
    }];
  } else {
    NSLog(@"Failed to get Firebase user.");
    completionHandler(nil, [[NSError alloc] initWithDomain:kMSSasquatchErrorDomain
                                                      code:MSFirebaseAuthUserNotFoundErrorCode
                                                  userInfo:@{NSLocalizedDescriptionKey : @"Failed to get Firebase user."}]);
  }
}

@end
