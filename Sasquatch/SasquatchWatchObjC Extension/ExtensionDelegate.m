#import "ExtensionDelegate.h"

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
}

- (void)applicationDidBecomeActive {
}

- (void)applicationWillResignActive {
}

- (void)handleBackgroundTasks:(NSSet<WKRefreshBackgroundTask *> *)backgroundTasks {
  for (WKRefreshBackgroundTask *task in backgroundTasks) {

    // Check the Class of each task to decide how to process it
    if ([task isKindOfClass:[WKApplicationRefreshBackgroundTask class]]) {

      // Be sure to complete the background task once you’re done.
      WKApplicationRefreshBackgroundTask *backgroundTask = (WKApplicationRefreshBackgroundTask *)task;
      [backgroundTask setTaskCompleted];
    } else if ([task isKindOfClass:[WKSnapshotRefreshBackgroundTask class]]) {

      // Snapshot tasks have a unique completion call, make sure to set your expiration date
      WKSnapshotRefreshBackgroundTask *snapshotTask = (WKSnapshotRefreshBackgroundTask *)task;
      [snapshotTask setTaskCompletedWithDefaultStateRestored:YES estimatedSnapshotExpiration:[NSDate distantFuture] userInfo:nil];
    } else if ([task isKindOfClass:[WKWatchConnectivityRefreshBackgroundTask class]]) {

      // Be sure to complete the background task once you’re done.
      WKWatchConnectivityRefreshBackgroundTask *backgroundTask = (WKWatchConnectivityRefreshBackgroundTask *)task;
      [backgroundTask setTaskCompleted];
    } else if ([task isKindOfClass:[WKURLSessionRefreshBackgroundTask class]]) {

      // Be sure to complete the background task once you’re done.
      WKURLSessionRefreshBackgroundTask *backgroundTask = (WKURLSessionRefreshBackgroundTask *)task;
      [backgroundTask setTaskCompleted];
    } else {

      // make sure to complete unhandled task types
      [task setTaskCompleted];
    }
  }
}

@end
