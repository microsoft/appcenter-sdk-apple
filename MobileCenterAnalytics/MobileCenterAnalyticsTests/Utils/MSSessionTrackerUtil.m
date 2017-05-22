#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import "MSSessionTrackerUtil.h"

@implementation MSSessionTrackerUtil

+ (void)simulateDidEnterBackgroundNotification {
  [[NSNotificationCenter defaultCenter]
#if TARGET_OS_IPHONE
      postNotificationName:UIApplicationDidEnterBackgroundNotification
#else
      postNotificationName:NSApplicationDidResignActiveNotification
#endif
                    object:self];
}

+ (void)simulateWillEnterForegroundNotification {
  // Enter foreground
  [[NSNotificationCenter defaultCenter]
#if TARGET_OS_IPHONE
      postNotificationName:UIApplicationWillEnterForegroundNotification
#else
      postNotificationName:NSApplicationWillBecomeActiveNotification
#endif
                    object:self];
}

@end
