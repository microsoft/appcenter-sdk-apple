// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <UIKit/UIScreen.h>
#import <UIKit/UIWindow.h>

#import "MSACAlertController.h"
#import "MSACDispatcherUtil.h"

static char *const MSACAlertsDispatchQueue = "com.microsoft.appcenter.alertsQueue";

@implementation MSACAlertAction

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

@interface MSACAlertController ()

@end

@implementation MSACAlertController

static UIWindow *window;
static BOOL alertIsBeingPresented;
static NSMutableArray *alertsToBePresented;
static dispatch_queue_t alertsQueue;

+ (void)initialize {
  alertIsBeingPresented = NO;
  alertsToBePresented = @[].mutableCopy;
  alertsQueue = dispatch_queue_create(MSACAlertsDispatchQueue, DISPATCH_QUEUE_CONCURRENT);

  UIViewController *emptyViewController = [UIViewController new];
  [emptyViewController.view setBackgroundColor:[UIColor clearColor]];

  window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  window.rootViewController = emptyViewController;
  window.backgroundColor = [UIColor clearColor];
  window.windowLevel = UIWindowLevelAlert + 1;
}

+ (instancetype)alertControllerWithTitle:(NSString *)title message:(NSString *)message {
  return [self alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  alertIsBeingPresented = NO;
  [MSACAlertController presentNextAlertAnimated:animated];
}

- (void)addDefaultActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler {
  [self addAction:[MSACAlertAction defaultActionWithTitle:title handler:handler]];
}

- (void)addCancelActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler {
  [self addAction:[MSACAlertAction cancelActionWithTitle:title handler:handler]];
}

- (void)addDestructiveActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler {
  [self addAction:[MSACAlertAction destructiveActionWithTitle:title handler:handler]];
}

- (void)addPreferredActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *))handler {

  // Use default style to allow button to be on right side (bolded with setPreferredAction).
  UIAlertAction *preferredAction = [MSACAlertAction defaultActionWithTitle:title handler:handler];
  [self addAction:preferredAction];
  [self performSelector:@selector(setPreferredAction:) withObject:preferredAction];
}

- (void)replaceAlert:(MSACAlertController *)alert {
  [self replaceAlert:alert animated:YES];
}

- (void)replaceAlert:(MSACAlertController *)alert animated:(BOOL)animated {
  if (alert) {
    __block MSACAlertController *alertToReplace = alert;
    dispatch_sync(alertsQueue, ^{
      NSUInteger toReplaceIndex = [alertsToBePresented indexOfObjectIdenticalTo:alertToReplace];
      if (toReplaceIndex != NSNotFound) {
        [alertsToBePresented replaceObjectAtIndex:toReplaceIndex withObject:self];
      } else {
        [alertsToBePresented addObject:self];
      }
    });

    // Try to present the alert now.
    [MSACAlertController presentNextAlertAnimated:animated];

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
  [MSACAlertController presentNextAlertAnimated:animated];
}

+ (void)presentNextAlertAnimated:(BOOL)animated {
  if (alertIsBeingPresented) {
    return;
  }
  MSACAlertController *__block nextAlert;
  dispatch_sync(alertsQueue, ^{
    nextAlert = alertsToBePresented.firstObject;
  });
  if (nextAlert) {
    alertIsBeingPresented = YES;
    dispatch_barrier_async(alertsQueue, ^{
      [alertsToBePresented removeObjectAtIndex:0];
    });
    dispatch_async(dispatch_get_main_queue(), ^{
      [MSACAlertController makeKeyAndVisible];
      [window.rootViewController presentViewController:nextAlert animated:animated completion:nil];
    });
  } else {
    window.hidden = YES;
    alertIsBeingPresented = NO;
  }
}

+ (void)makeKeyAndVisible {
  if (@available(iOS 13.0, tvOS 13.0, *)) {
    UIApplication *application = MSAC_DISPATCH_SELECTOR((UIApplication * (*)(id, SEL)), [UIApplication class], sharedApplication);
    NSSet *scenes = MSAC_DISPATCH_SELECTOR((NSSet * (*)(id, SEL)), application, connectedScenes);
    NSObject *windowScene = nil;
    for (NSObject *scene in scenes) {
      NSInteger activationState = MSAC_DISPATCH_SELECTOR((NSInteger(*)(id, SEL)), scene, activationState);
      if (activationState == 0 /* UISceneActivationStateForegroundActive */) {
        windowScene = scene;
        break;
      }
    }
    if (!windowScene) {
      windowScene = scenes.anyObject;
    }
    MSAC_DISPATCH_SELECTOR((void (*)(id, SEL, typeof(windowScene))), window, setWindowScene:, windowScene);
  }
  [window makeKeyAndVisible];
}

@end
