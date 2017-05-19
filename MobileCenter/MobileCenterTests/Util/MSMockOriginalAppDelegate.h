#import <UIKit/UIKit.h>

typedef BOOL (^OriginalOpenURLiOS42Validator)(UIApplication *, NSURL *, NSString *, id);
typedef BOOL (^OriginalDidRegisterNotificationValidator)(UIApplication *, NSData *);
typedef BOOL (^OriginalDidReceiveNotification)(UIApplication *, NSDictionary *, void (^)(UIBackgroundFetchResult));

/*
 * We Can't use OCMock to mock original app delegate since the class needs to own the method implementation.
 * We also can't use OCMock's protocol mocks since they artificially responds to any selector from the protocol.
 * Adding this class that can be used for both custom and original delegate to solve the issue for some tests.
 */
@interface MSMockOriginalAppDelegate : NSObject <UIApplicationDelegate>

@property(nonatomic, readonly) NSMutableDictionary<NSString *, id> *delegateValidators;

@end
