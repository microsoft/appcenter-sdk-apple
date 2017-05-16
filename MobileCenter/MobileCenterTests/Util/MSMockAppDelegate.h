#import <UIKit/UIKit.h>

#import "MSAppDelegate.h"

typedef BOOL (^OriginalOpenURLiOS42Validator)(UIApplication *, NSURL *, NSString *, id);
typedef BOOL (^CustomOpenURLiOS42Validator)(UIApplication *, NSURL *, NSString *, id, BOOL);
typedef BOOL (^CustomOpenURLiOS9Validator)(UIApplication *, NSURL *, NSDictionary<UIApplicationOpenURLOptionsKey, id> *,
                                           BOOL);

/*
 * We Can't use OCMock to mock original app delegate since the class needs to own the method implementation.
 * We also can't use OCMock's protocol mocks since they artificially responds to any selector from the protocol.
 * Adding this class that can be used for both custom and original delegate to solve the issue for some tests.
 */
@interface MSMockAppDelegate : NSObject <UIApplicationDelegate, MSAppDelegate>

@property(nonatomic, readonly) NSMutableDictionary<NSString *, id> *originalDelegateValidators;
@property(nonatomic, readonly) NSMutableDictionary<NSString *, id> *customDelegateValidators;

@end

/*
 * Class without UIApplicationDelegate implementation
 */
@interface MSChildMockAppDelegateWithoutImplementation : MSMockAppDelegate

@end

/*
 * Class with UIApplicationDelegate implementation
 */
@interface MSChildMockAppDelegateWithImplementation : MSMockAppDelegate

@end

/*
 * Base class without UIApplicationDelegate implementation
 */
@interface MCBaseMockAppDelegateWithoutImplementation : NSObject <UIApplicationDelegate, MSAppDelegate>

@property(nonatomic, readonly) NSMutableDictionary<NSString *, id> *originalDelegateValidators;
@property(nonatomic, readonly) NSMutableDictionary<NSString *, id> *customDelegateValidators;

@end

/*
 * Class with UIApplicationDelegate implementation
 */
@interface MSChildMockAppDelegateWithoutImpInBaseClass : MCBaseMockAppDelegateWithoutImplementation

@end
