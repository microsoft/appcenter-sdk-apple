// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <UIKit/UIScreen.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIScene.h>

#import "MSAlertController.h"

static char *const MSAlertsDispatchQueue = "com.microsoft.appcenter.alertsQueue";

@implementation MSAlertAction

+ (instancetype)defaultActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler {
  return [self actionWithTitle:title style:UIAlertActionStyleDefault handler:handler];
}

+ (instancetype)cancelActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler {
  return [self actionWithTitle:title style:UIAlertActionStyleCancel handler:handler];
}

+ (instancetype)destructiveActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler {
  return [self actionWithTitle:title style:UIAlertActionStyleDestructive handler:handler];
}

@end

@interface MSAlertController ()

@end

@implementation MSAlertController

static UIWindow *window;
static BOOL alertIsBeingPresented;
static NSMutableArray *alertsToBePresented;
static dispatch_queue_t alertsQueue;

+ (void)initialize {
  alertIsBeingPresented = NO;
  alertsToBePresented = @[].mutableCopy;
  alertsQueue = dispatch_queue_create(MSAlertsDispatchQueue, DISPATCH_QUEUE_CONCURRENT);

  UIViewController *emptyViewController = [UIViewController new];
  [emptyViewController.view setBackgroundColor:[UIColor clearColor]];

  if ([self resolveUiWindow]){
    window.rootViewController = emptyViewController;
    window.backgroundColor = [UIColor clearColor];
    window.windowLevel = UIWindowLevelAlert + 1;
  }
}

+ (BOOL)resolveUiWindow {
  if (@available(iOS 13.0, *)) {
    UIWindowScene *mainScene = nil;
    NSSet<UIScene *> *scenes = [UIApplication sharedApplication].connectedScenes;

    // There may be a situation where none of the scenes is active.
    UIWindowScene *fallbackScene = nil;
    for (UIScene *scene in scenes) {
      if (scene.activationState != UISceneActivationStateUnattached) {
        fallbackScene = (UIWindowScene*) scene;
      }
      if (scene.activationState == UISceneActivationStateForegroundActive) {
        mainScene = (UIWindowScene*) scene;
        break;
      }
    }
    if (mainScene != nil) {
      window = [[UIWindow alloc] initWithWindowScene:mainScene];
    } else {
      window = [[UIWindow alloc] initWithWindowScene:fallbackScene];
    }
  } else {
    window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  }
  return window != nil;
}

+ (instancetype)alertControllerWithTitle:(NSString *)title message:(NSString *)message {
  return [self alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  alertIsBeingPresented = NO;
  [MSAlertController presentNextAlertAnimated:animated];
}

- (void)addDefaultActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler {
  [self addAction:[MSAlertAction defaultActionWithTitle:title handler:handler]];
}

- (void)addCancelActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler {
  [self addAction:[MSAlertAction cancelActionWithTitle:title handler:handler]];
}

- (void)addDestructiveActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler {
  [self addAction:[MSAlertAction destructiveActionWithTitle:title handler:handler]];
}

- (void)addPreferredActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler {

  // Use default style to allow button to be on right side (bolded with setPreferredAction).
  UIAlertAction *preferredAction = preferredAction = [MSAlertAction defaultActionWithTitle:title handler:handler];
  [self addAction:preferredAction];
  [self performSelector:@selector(setPreferredAction:) withObject:preferredAction];
}

- (void)replaceAlert:(MSAlertController *)alert {
  [self replaceAlert:alert animated:YES];
}

- (void)replaceAlert:(MSAlertController *)alert animated:(BOOL)animated {
  if (alert) {
    __block MSAlertController *alertToReplace = alert;
    dispatch_sync(alertsQueue, ^{
      NSUInteger toReplaceIndex = [alertsToBePresented indexOfObjectIdenticalTo:alertToReplace];
      if (toReplaceIndex != NSNotFound) {
        [alertsToBePresented replaceObjectAtIndex:toReplaceIndex withObject:self];
      } else {
        [alertsToBePresented addObject:self];
      }
    });

    // Try to present the alert now.
    [MSAlertController presentNextAlertAnimated:animated];

    // The alert to replace might be presenting, dismissing it.
    dispatch_async(dispatch_get_main_queue(), ^{
      if (window.rootViewController.presentedViewController == alertToReplace) {
        [alertToReplace dismissViewControllerAnimated:animated completion:nil];
      }
    });
  }

  // The alert to replace is nil, follow the basic workflow.
  else {
    [self showAnimated:YES];
  }
}

- (void)show {
  [self showAnimated:YES];
}

- (void)showAnimated:(BOOL)animated {
  dispatch_barrier_async(alertsQueue, ^{
    [alertsToBePresented addObject:self];
  });
  [MSAlertController presentNextAlertAnimated:animated];
}

+ (void)presentNextAlertAnimated:(BOOL)animated {
  if (alertIsBeingPresented) {
    return;
  }
  MSAlertController *__block nextAlert;
  dispatch_sync(alertsQueue, ^{
    nextAlert = alertsToBePresented.firstObject;
  });
  if (nextAlert) {
    alertIsBeingPresented = YES;
    dispatch_barrier_async(alertsQueue, ^{
      [alertsToBePresented removeObjectAtIndex:0];
    });
    dispatch_async(dispatch_get_main_queue(), ^{
      [window makeKeyAndVisible];
      [window.rootViewController presentViewController:nextAlert animated:animated completion:nil];
    });
  } else {
    window.hidden = YES;
    alertIsBeingPresented = NO;
  }
}

@end
