#import <UIKit/UIWindow.h>
#import <UIKit/UIScreen.h>

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
  [MSAlertController presentNextPendingAlertController];
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

- (void)show {
  [self showAnimated:YES];
}

- (void)showAnimated:(BOOL)animated {
  dispatch_barrier_async(alertsQueue, ^{
      [alertsToBePresented addObject:self];
  });
  [MSAlertController presentNextPendingAlertController];
}

+ (void)presentNextPendingAlertController {
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
        [window.rootViewController presentViewController:nextAlert animated:YES completion:nil];
    });
  } else {
    window.hidden = YES;
    alertIsBeingPresented = NO;
  }
}

@end
