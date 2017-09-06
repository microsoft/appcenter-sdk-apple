#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#import "MSNSAppDelegate.h"
#else
#import <UIKit/UIKit.h>
#import "MSUIAppDelegate.h"
#endif

#if TARGET_OS_OSX
typedef BOOL (^CustomDidRegisterNotificationValidator)(NSApplication *, NSData *);
typedef BOOL (^CustomDidFinishLaunchingValidator)(NSNotification *);
#else
typedef BOOL (^CustomOpenURLiOS42Validator)(UIApplication *, NSURL *, NSString *, id, BOOL);
typedef BOOL (^CustomOpenURLiOS9Validator)(UIApplication *, NSURL *, NSDictionary<UIApplicationOpenURLOptionsKey, id> *,
                                           BOOL);
typedef BOOL (^CustomDidRegisterNotificationValidator)(UIApplication *, NSData *);
typedef BOOL (^CustomDidReceiveNotificationWorkaroundValidator)(UIApplication *application, NSDictionary *userInfo);
typedef BOOL (^CustomDidReceiveNotificationValidator)(UIApplication *application, NSDictionary *userInfo,
                                                      void (^fetchHandler)(UIBackgroundFetchResult));
#endif

/*
 * We Can't use OCMock to mock original app delegate since the class needs to own the method implementation.
 * We also can't use OCMock's protocol mocks since they artificially responds to any selector from the protocol.
 * Adding this class that can be used for both custom and original delegate to solve the issue for some tests.
 */
@interface MSMockCustomAppDelegate : NSObject <MSApplicationDelegate, MSAppDelegate>

@property(nonatomic, readonly) NSMutableDictionary<NSString *, id> *delegateValidators;

@end
