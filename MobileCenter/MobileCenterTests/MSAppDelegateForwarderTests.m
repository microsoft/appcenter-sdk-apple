#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#import "MSNSAppDelegate.h"
#define MSApplication NSApplication
#else
#import <UIKit/UIKit.h>
#import "MSUIAppDelegate.h"
#define MSApplication UIApplication
#endif

#import "MSAppDelegateForwarderPrivate.h"
#import "MSMockCustomAppDelegate.h"
#import "MSMockOriginalAppDelegate.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Application.h"

@interface MSAppDelegateForwarderTest : XCTestCase

@property(nonatomic) MSMockOriginalAppDelegate *originalAppDelegateMock;
@property(nonatomic) MSMockCustomAppDelegate *customAppDelegateMock;
@property(nonatomic) MSApplication *appMock;

@end

/*
 * We use of blocks for test validition but test frameworks contain macro capturing self that we can't avoid.
 * Ignoring retain cycle warning for this test code.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"

// Silence application:openURL:options: availability warning (iOS 9) for the whole test.
#pragma clang diagnostic ignored "-Wpartial-availability"

@implementation MSAppDelegateForwarderTest

- (void)setUp {
  [super setUp];

  // Mock app delegate.
  self.appMock = OCMClassMock([MSApplication class]);
  self.originalAppDelegateMock = [MSMockOriginalAppDelegate new];
  self.customAppDelegateMock = [MSMockCustomAppDelegate new];
  id utilMock = OCMClassMock([MSUtility class]);
  OCMStub([utilMock sharedAppDelegate]).andReturn(self.originalAppDelegateMock);
}

- (void)tearDown {

  // Clear delegates.
  MSAppDelegateForwarder.delegates = [NSHashTable new];
  [super tearDown];
}

- (void)testAddAppDelegateSelectorToSwizzle {

  // If
  NSUInteger currentCount = MSAppDelegateForwarder.selectorsToSwizzle.count;
  SEL expectedSelector = @selector(testAddAppDelegateSelectorToSwizzle);
  NSString *expectedSelectorStr = NSStringFromSelector(expectedSelector);

  // Then
  assertThatBool([MSAppDelegateForwarder.selectorsToSwizzle containsObject:expectedSelectorStr], isFalse());

  // When
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:expectedSelector];

  // Then
  assertThatInteger(MSAppDelegateForwarder.selectorsToSwizzle.count, equalToInteger(currentCount + 1));
  assertThatBool([MSAppDelegateForwarder.selectorsToSwizzle containsObject:expectedSelectorStr], isTrue());

  // When
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:expectedSelector];

  // Then
  assertThatInteger(MSAppDelegateForwarder.selectorsToSwizzle.count, equalToInteger(currentCount + 1));
  assertThatBool([MSAppDelegateForwarder.selectorsToSwizzle containsObject:expectedSelectorStr], isTrue());
  [MSAppDelegateForwarder.selectorsToSwizzle removeObject:expectedSelectorStr];
}

- (void)testSwizzleOriginalPushDelegate {

  /*
   * If
   */

  // Mock a custom app delegate.
  id<MSAppDelegate> customDelegate = OCMProtocolMock(@protocol(MSAppDelegate));
  [MSAppDelegateForwarder addDelegate:customDelegate];
  NSError *expectedError = [[NSError alloc] initWithDomain:NSItemProviderErrorDomain code:123 userInfo:@{}];

  // App delegate not implementing any selector.
  Class originalAppDelegateClass = [self createClassConformingToProtocol:@protocol(MSApplicationDelegate)];
  id<MSApplicationDelegate> originalAppDelegate = [originalAppDelegateClass new];
  SEL selectorToSwizzle = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock didFailToRegisterForRemoteNotificationsWithError:expectedError];

  /*
   * Then
   */
  assertThatBool([originalAppDelegate respondsToSelector:selectorToSwizzle], isTrue());
  OCMVerify([customDelegate application:self.appMock didFailToRegisterForRemoteNotificationsWithError:expectedError]);

  /*
   * If
   */

  // App delegate implementing the selector directly.
  originalAppDelegateClass = [self createClassConformingToProtocol:@protocol(MSApplicationDelegate)];
  __block BOOL wasCalled = NO;
  id selectorImp = ^{
    wasCalled = YES;
  };
  Method method = class_getInstanceMethod(originalAppDelegateClass, selectorToSwizzle);
  const char *types = method_getTypeEncoding(method);
  [self addSelector:selectorToSwizzle implementation:selectorImp types:types toClass:originalAppDelegateClass];
  originalAppDelegate = [originalAppDelegateClass new];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock didFailToRegisterForRemoteNotificationsWithError:expectedError];

  /*
   * Then
   */
  assertThatBool([originalAppDelegate respondsToSelector:selectorToSwizzle], isTrue());
  assertThatBool(wasCalled, isTrue());
  OCMVerify([customDelegate application:self.appMock didFailToRegisterForRemoteNotificationsWithError:expectedError]);

  /*
   * If
   */

  // App delegate implementing the selector indirectly.
  Class baseClass = [self createClassConformingToProtocol:@protocol(MSApplicationDelegate)];
  [self addSelector:selectorToSwizzle implementation:selectorImp types:types toClass:baseClass];
  originalAppDelegateClass = [self createClassWithBaseClass:baseClass andConformItToProtocol:nil];
  wasCalled = NO;
  originalAppDelegate = [originalAppDelegateClass new];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock didFailToRegisterForRemoteNotificationsWithError:expectedError];

  /*
   * Then
   */
  assertThatBool([originalAppDelegate respondsToSelector:selectorToSwizzle], isTrue());
  assertThatBool(wasCalled, isTrue());
  OCMVerify([customDelegate application:self.appMock didFailToRegisterForRemoteNotificationsWithError:expectedError]);

  /*
   * If
   */

  // App delegate implementing the selector directly and indirectly.
  wasCalled = NO;
  __block BOOL baseWasCalled = NO;
  id baseSelectorImp = ^{
    baseWasCalled = YES;
  };
  baseClass = [self createClassConformingToProtocol:@protocol(MSApplicationDelegate)];
  [self addSelector:selectorToSwizzle implementation:baseSelectorImp types:types toClass:baseClass];
  originalAppDelegateClass = [self createClassWithBaseClass:baseClass andConformItToProtocol:nil];
  [self addSelector:selectorToSwizzle implementation:selectorImp types:types toClass:originalAppDelegateClass];
  originalAppDelegate = [originalAppDelegateClass new];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock didFailToRegisterForRemoteNotificationsWithError:expectedError];

  /*
   * Then
   */
  assertThatBool([originalAppDelegate respondsToSelector:selectorToSwizzle], isTrue());
  assertThatBool(wasCalled, isTrue());
  assertThatBool(baseWasCalled, isFalse());
  OCMVerify([customDelegate application:self.appMock didFailToRegisterForRemoteNotificationsWithError:expectedError]);

  /*
   * If
   */

  // App delegate not implementing any selector still responds to selector.
  originalAppDelegateClass = [self createClassConformingToProtocol:@protocol(MSApplicationDelegate)];
  SEL instancesRespondToSelector = @selector(instancesRespondToSelector:);
  id instancesRespondToSelectorImp = ^{
    return YES;
  };
  method = class_getClassMethod(originalAppDelegateClass, instancesRespondToSelector);
  const char *instancesRespondToSelectorTypes = method_getTypeEncoding(method);

  // Adding a class method to a class requires its meta class.
  Class originalAppDelegateMetaClass = object_getClass(originalAppDelegateClass);
  [self addSelector:instancesRespondToSelector
      implementation:instancesRespondToSelectorImp
               types:instancesRespondToSelectorTypes
             toClass:originalAppDelegateMetaClass];
  originalAppDelegate = [originalAppDelegateClass new];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];

  /*
   * Then
   */

  // Original delegate still responding to selector.
  assertThatBool([originalAppDelegateClass instancesRespondToSelector:selectorToSwizzle], isTrue());

  // Swizzling did not happened so no method added/replaced for this selector.
  assertThatBool(class_getInstanceMethod(originalAppDelegateClass, selectorToSwizzle) == NULL, isTrue());
}

#if !TARGET_OS_OSX
- (void)testSwizzleOriginalOpenURLDelegate {

  /*
   * If
   */

  // Mock a custom app delegate.
  id<MSAppDelegate> customDelegate = OCMProtocolMock(@protocol(MSAppDelegate));
  [MSAppDelegateForwarder addDelegate:customDelegate];
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedOptions = @{};

  // App delegate not implementing any selector.
  Class originalAppDelegateClass = [self createClassConformingToProtocol:@protocol(MSApplicationDelegate)];
  id<MSApplicationDelegate> originalAppDelegate = [originalAppDelegateClass new];
  SEL selectorToSwizzle = @selector(application:openURL:options:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock openURL:expectedURL options:expectedOptions];

  /*
   * Then
   */
  assertThatBool([originalAppDelegate respondsToSelector:selectorToSwizzle], isTrue());
  OCMVerify([customDelegate application:self.appMock openURL:expectedURL options:expectedOptions returnedValue:NO]);

  /*
   * If
   */

  // App delegate implementing the selector directly.
  originalAppDelegateClass = [self createClassConformingToProtocol:@protocol(MSApplicationDelegate)];
  __block BOOL wasCalled = NO;
  id selectorImp = ^{
    wasCalled = YES;
    return YES;
  };
  Method method = class_getInstanceMethod(originalAppDelegateClass, selectorToSwizzle);
  const char *types = method_getTypeEncoding(method);
  [self addSelector:selectorToSwizzle implementation:selectorImp types:types toClass:originalAppDelegateClass];
  originalAppDelegate = [originalAppDelegateClass new];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock openURL:expectedURL options:expectedOptions];

  /*
   * Then
   */
  assertThatBool([originalAppDelegate respondsToSelector:selectorToSwizzle], isTrue());
  assertThatBool(wasCalled, isTrue());
  OCMVerify([customDelegate application:self.appMock openURL:expectedURL options:expectedOptions returnedValue:YES]);

  /*
   * If
   */

  // App delegate implementing the selector indirectly.
  Class baseClass = [self createClassConformingToProtocol:@protocol(MSApplicationDelegate)];
  [self addSelector:selectorToSwizzle implementation:selectorImp types:types toClass:baseClass];
  originalAppDelegateClass = [self createClassWithBaseClass:baseClass andConformItToProtocol:nil];
  wasCalled = NO;
  originalAppDelegate = [originalAppDelegateClass new];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock openURL:expectedURL options:expectedOptions];

  /*
   * Then
   */
  assertThatBool([originalAppDelegate respondsToSelector:selectorToSwizzle], isTrue());
  assertThatBool(wasCalled, isTrue());
  OCMVerify([customDelegate application:self.appMock openURL:expectedURL options:expectedOptions returnedValue:YES]);

  /*
   * If
   */

  // App delegate implementing the selector directly and indirectly.
  wasCalled = NO;
  __block BOOL baseWasCalled = NO;
  id baseSelectorImp = ^{
    baseWasCalled = YES;
  };
  baseClass = [self createClassConformingToProtocol:@protocol(MSApplicationDelegate)];
  [self addSelector:selectorToSwizzle implementation:baseSelectorImp types:types toClass:baseClass];
  originalAppDelegateClass = [self createClassWithBaseClass:baseClass andConformItToProtocol:nil];
  [self addSelector:selectorToSwizzle implementation:selectorImp types:types toClass:originalAppDelegateClass];
  originalAppDelegate = [originalAppDelegateClass new];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock openURL:expectedURL options:expectedOptions];

  /*
   * Then
   */
  assertThatBool([originalAppDelegate respondsToSelector:selectorToSwizzle], isTrue());
  assertThatBool(wasCalled, isTrue());
  assertThatBool(baseWasCalled, isFalse());
  OCMVerify([customDelegate application:self.appMock openURL:expectedURL options:expectedOptions returnedValue:YES]);

  /*
   * If
   */

  // App delegate not implementing any selector still responds to selector.
  originalAppDelegateClass = [self createClassConformingToProtocol:@protocol(MSApplicationDelegate)];
  SEL instancesRespondToSelector = @selector(instancesRespondToSelector:);
  id instancesRespondToSelectorImp = ^{
    return YES;
  };
  method = class_getClassMethod(originalAppDelegateClass, instancesRespondToSelector);
  const char *instancesRespondToSelectorTypes = method_getTypeEncoding(method);

  // Adding a class method to a class requires its meta class.
  Class originalAppDelegateMetaClass = object_getClass(originalAppDelegateClass);
  [self addSelector:instancesRespondToSelector
      implementation:instancesRespondToSelectorImp
               types:instancesRespondToSelectorTypes
             toClass:originalAppDelegateMetaClass];
  originalAppDelegate = [originalAppDelegateClass new];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];

  /*
   * Then
   */

  // Original delegate still responding to selector.
  assertThatBool([originalAppDelegateClass instancesRespondToSelector:selectorToSwizzle], isTrue());

  // Swizzling did not happened so no method added/replaced for this selector.
  assertThatBool(class_getInstanceMethod(originalAppDelegateClass, selectorToSwizzle) == NULL, isTrue());
}
#endif

- (void)testForwardUnknownSelector {

  /*
   * If
   */

  // Calling an unknown selector on the forwarder must still throw an exception.
  XCTestExpectation *exceptionCaughtExpectation =
      [self expectationWithDescription:@"Caught!! That exception will go nowhere."];

  /*
   * When
   */
  @try {
    [[MSAppDelegateForwarder new] performSelector:@selector(testForwardUnknownSelector)];
  } @catch (NSException *ex) {

    /*
     * Then
     */
    assertThat(ex.name, is(NSInvalidArgumentException));
    assertThatBool([ex.reason containsString:@"unrecognized selector sent"], isTrue());
    [exceptionCaughtExpectation fulfill];
  }
  [self waitForExpectations:@[ exceptionCaughtExpectation ] timeout:1];
}

#if !TARGET_OS_OSX
- (void)testWithoutCustomDelegate {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL expectedReturnedValue = YES;
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  SEL originalOpenURLiOS42Sel = @selector(application:openURL:sourceApplication:annotation:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalOpenURLiOS42Sel];
  self.originalAppDelegateMock.delegateValidators[NSStringFromSelector(originalOpenURLiOS42Sel)] =
      ^(MSApplication *application, NSURL *url, NSString *sApplication, id annotation) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        [originalCalledExpectation fulfill];
        return expectedReturnedValue;
      };

  // When
  BOOL returnedValue = [self.originalAppDelegateMock application:self.appMock
                                                         openURL:expectedURL
                                               sourceApplication:nil
                                                      annotation:expectedAnnotation];

  // Then
  assertThatUnsignedLong(MSAppDelegateForwarder.delegates.count, equalToUnsignedLong(0));
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
}
#endif

- (void)testWithoutCustomDelegateNotReturningValue {

  // If
  NSData *expectedToken = [@"Device token" dataUsingEncoding:NSUTF8StringEncoding];
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  SEL originalDidRegisterForRemoteNotificationsWithDeviceTokenSel =
      @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalDidRegisterForRemoteNotificationsWithDeviceTokenSel];
  self.originalAppDelegateMock
      .delegateValidators[NSStringFromSelector(originalDidRegisterForRemoteNotificationsWithDeviceTokenSel)] =
      ^(MSApplication *application, NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [originalCalledExpectation fulfill];
      };

  // When
  [self.originalAppDelegateMock application:self.appMock
      didRegisterForRemoteNotificationsWithDeviceToken:expectedToken];

  // Then
  assertThatUnsignedLong(MSAppDelegateForwarder.delegates.count, equalToUnsignedLong(0));
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
}

#if !TARGET_OS_OSX
- (void)testWithOneCustomDelegate {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL expectedReturnedValue = YES;
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  XCTestExpectation *customCalledExpectation = [self expectationWithDescription:@"Custom delegate called."];
  SEL originalOpenURLiOS42Sel = @selector(application:openURL:sourceApplication:annotation:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalOpenURLiOS42Sel];
  self.originalAppDelegateMock.delegateValidators[NSStringFromSelector(originalOpenURLiOS42Sel)] =
      ^(MSApplication *application, NSURL *url, NSString *sApplication, id annotation) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        [originalCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  NSString *customOpenURLiOS42Str =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:returnedValue:));
  self.customAppDelegateMock.delegateValidators[customOpenURLiOS42Str] =
      ^(MSApplication *application, NSURL *url, NSString *sApplication, id annotation, BOOL returnedValue) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        assertThatBool(returnedValue, is(@(expectedReturnedValue)));
        [customCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  [MSAppDelegateForwarder addDelegate:self.customAppDelegateMock];

  // When
  BOOL returnedValue = [self.originalAppDelegateMock application:self.appMock
                                                         openURL:expectedURL
                                               sourceApplication:nil
                                                      annotation:expectedAnnotation];

  // Then
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ originalCalledExpectation, customCalledExpectation ] timeout:1];
}
#endif

- (void)testWithOneCustomDelegateNotReturningValue {

  // If
  NSData *expectedToken = [@"Device token" dataUsingEncoding:NSUTF8StringEncoding];
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  XCTestExpectation *customCalledExpectation = [self expectationWithDescription:@"Custom delegate called."];
  SEL didRegisterNotificationSel = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
  NSString *didRegisterNotificationStr = NSStringFromSelector(didRegisterNotificationSel);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didRegisterNotificationSel];
  self.originalAppDelegateMock.delegateValidators[didRegisterNotificationStr] =
      ^(MSApplication *application, NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [originalCalledExpectation fulfill];
      };
  self.customAppDelegateMock.delegateValidators[didRegisterNotificationStr] =
      ^(MSApplication *application, NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [customCalledExpectation fulfill];
      };
  [MSAppDelegateForwarder addDelegate:self.customAppDelegateMock];

  // When
  [self.originalAppDelegateMock application:appMock didRegisterForRemoteNotificationsWithDeviceToken:expectedToken];

  // Then
  [self waitForExpectations:@[ originalCalledExpectation, customCalledExpectation ] timeout:1];
}

#if !TARGET_OS_OSX
- (void)testDontForwardSelectorsNotToOverrideIfAlreadyImplementedByOriginalDelegate {

  // If
  NSDictionary *expectedUserInfo = @{ @"key" : @"value" };
  void (^expectedCompletionHandler)(UIBackgroundFetchResult result) =
      ^(__attribute__((unused)) UIBackgroundFetchResult result) {
      };
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  SEL didReceiveRemoteNotificationSel = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
  NSString *didReceiveRemoteNotificationStr = NSStringFromSelector(didReceiveRemoteNotificationSel);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];
  self.originalAppDelegateMock.delegateValidators[didReceiveRemoteNotificationStr] =
      ^(MSApplication *application, NSDictionary *userInfo, void (^completionHandler)(UIBackgroundFetchResult result)) {

        // Then
        assertThat(application, is(appMock));
        assertThat(userInfo, is(expectedUserInfo));
        assertThat(completionHandler, is(expectedCompletionHandler));
        [originalCalledExpectation fulfill];
      };
  self.customAppDelegateMock.delegateValidators[didReceiveRemoteNotificationStr] =
      ^(__attribute__((unused)) MSApplication *application, __attribute__((unused)) NSData *deviceToken) {

        // Then
        XCTFail(@"This method is already implemented in the original delegate and is marked not to be swizzled.");
      };
  [MSAppDelegateForwarder addDelegate:self.customAppDelegateMock];

  // When
  [self.originalAppDelegateMock application:appMock
               didReceiveRemoteNotification:expectedUserInfo
                     fetchCompletionHandler:expectedCompletionHandler];

  // Then
  assertThatBool([MSAppDelegateForwarder.selectorsNotToOverride containsObject:didReceiveRemoteNotificationStr],
                 isTrue());
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
}
#endif

#if !TARGET_OS_OSX
- (void)testWithMultipleCustomOpenURLDelegates {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL expectedReturnedValue = YES;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  XCTestExpectation *customCalledExpectation1 = [self expectationWithDescription:@"Custom delegate 1 called."];
  XCTestExpectation *customCalledExpectation2 = [self expectationWithDescription:@"Custom delegate 2 called."];
  MSApplication *appMock = self.appMock;
  SEL originalOpenURLiOS42Sel = @selector(application:openURL:sourceApplication:annotation:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalOpenURLiOS42Sel];
  self.originalAppDelegateMock.delegateValidators[NSStringFromSelector(originalOpenURLiOS42Sel)] =
      ^(MSApplication *application, NSURL *url, NSString *sApplication, id annotation) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        [originalCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  MSMockCustomAppDelegate *customAppDelegateMock1 = [MSMockCustomAppDelegate new];
  NSString *customOpenURLiOS42Str =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:returnedValue:));
  customAppDelegateMock1.delegateValidators[customOpenURLiOS42Str] =
      ^(MSApplication *application, NSURL *url, NSString *sApplication, id annotation, BOOL returnedValue) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        assertThatBool(returnedValue, is(@(expectedReturnedValue)));
        [customCalledExpectation1 fulfill];
        return expectedReturnedValue;
      };
  MSMockCustomAppDelegate *customAppDelegateMock2 = [MSMockCustomAppDelegate new];
  customAppDelegateMock2.delegateValidators[customOpenURLiOS42Str] =
      ^(MSApplication *application, NSURL *url, NSString *sApplication, id annotation, BOOL returnedValue) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        assertThatBool(returnedValue, is(@(expectedReturnedValue)));
        [customCalledExpectation2 fulfill];
        return expectedReturnedValue;
      };
  [MSAppDelegateForwarder addDelegate:customAppDelegateMock1];
  [MSAppDelegateForwarder addDelegate:customAppDelegateMock2];

  // When
  BOOL returnedValue = [self.originalAppDelegateMock application:self.appMock
                                                         openURL:expectedURL
                                               sourceApplication:nil
                                                      annotation:expectedAnnotation];

  // Then
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ originalCalledExpectation, customCalledExpectation1, customCalledExpectation2 ]
                    timeout:1];
}
#endif

- (void)testWithMultipleCustomPushDelegates {

  // If
  NSData *expectedToken = [@"Device token" dataUsingEncoding:NSUTF8StringEncoding];
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  XCTestExpectation *customCalledExpectation1 = [self expectationWithDescription:@"Custom delegate 1 called."];
  XCTestExpectation *customCalledExpectation2 = [self expectationWithDescription:@"Custom delegate 2 called."];
  MSApplication *appMock = self.appMock;
  SEL originalDidRegisterForRemoteNotificationWithDeviceTokenSel =
      @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalDidRegisterForRemoteNotificationWithDeviceTokenSel];
  self.originalAppDelegateMock
      .delegateValidators[NSStringFromSelector(originalDidRegisterForRemoteNotificationWithDeviceTokenSel)] =
      ^(MSApplication *application, NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [originalCalledExpectation fulfill];
      };
  MSMockCustomAppDelegate *customAppDelegateMock1 = [MSMockCustomAppDelegate new];
  NSString *customDidRegisterForRemoteNotificationWithDeviceTokenStr =
      NSStringFromSelector(@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
  customAppDelegateMock1.delegateValidators[customDidRegisterForRemoteNotificationWithDeviceTokenStr] =
      ^(MSApplication *application, NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [customCalledExpectation1 fulfill];
      };
  MSMockCustomAppDelegate *customAppDelegateMock2 = [MSMockCustomAppDelegate new];
  customAppDelegateMock2.delegateValidators[customDidRegisterForRemoteNotificationWithDeviceTokenStr] =
      ^(MSApplication *application, NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [customCalledExpectation2 fulfill];
      };
  [MSAppDelegateForwarder addDelegate:customAppDelegateMock1];
  [MSAppDelegateForwarder addDelegate:customAppDelegateMock2];

  // When
  [self.originalAppDelegateMock application:self.appMock
      didRegisterForRemoteNotificationsWithDeviceToken:expectedToken];

  // Then
  [self waitForExpectations:@[ originalCalledExpectation, customCalledExpectation1, customCalledExpectation2 ]
                    timeout:1];
}

#if !TARGET_OS_OSX
- (void)testWithRemovedCustomOpenURLDelegate {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL expectedReturnedValue = YES;
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  SEL originalOpenURLiOS42Sel = @selector(application:openURL:sourceApplication:annotation:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalOpenURLiOS42Sel];
  self.originalAppDelegateMock.delegateValidators[NSStringFromSelector(originalOpenURLiOS42Sel)] =
      ^(MSApplication *application, NSURL *url, NSString *sApplication, id annotation) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        [originalCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  NSString *customOpenURLiOS42Str =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:returnedValue:));
  self.customAppDelegateMock.delegateValidators[customOpenURLiOS42Str] =
      ^(__attribute__((unused)) MSApplication *application, __attribute__((unused)) NSURL *url,
        __attribute__((unused)) NSString *sApplication, __attribute__((unused)) id annotation,
        __attribute__((unused)) BOOL returnedValue) {

        // Then
        XCTFail(@"Custom delegate got called but is removed.");
        return expectedReturnedValue;
      };
  [MSAppDelegateForwarder addDelegate:self.customAppDelegateMock];
  [MSAppDelegateForwarder removeDelegate:self.customAppDelegateMock];

  // When
  BOOL returnedValue = [self.originalAppDelegateMock application:self.appMock
                                                         openURL:expectedURL
                                               sourceApplication:nil
                                                      annotation:expectedAnnotation];

  // Then
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
}
#endif

- (void)testWithRemovedCustomDidRegisterForRemoteNotificationWithDeviceTokenDelegate {

  // If
  NSData *expectedToken = [@"Device token" dataUsingEncoding:NSUTF8StringEncoding];
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  SEL originalDidRegisterForRemoteNotificationWithDeviceTokenSel =
      @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalDidRegisterForRemoteNotificationWithDeviceTokenSel];
  self.originalAppDelegateMock
      .delegateValidators[NSStringFromSelector(originalDidRegisterForRemoteNotificationWithDeviceTokenSel)] =
      ^(MSApplication *application, NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [originalCalledExpectation fulfill];
      };
  NSString *customDidRegisterForRemoteNotificationWithDeviceTokenStr =
      NSStringFromSelector(@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
  self.customAppDelegateMock.delegateValidators[customDidRegisterForRemoteNotificationWithDeviceTokenStr] =
      ^(__attribute__((unused)) MSApplication *application, __attribute__((unused)) NSData *deviceToken) {

        // Then
        XCTFail(@"Custom delegate got called but is removed.");
      };
  [MSAppDelegateForwarder addDelegate:self.customAppDelegateMock];
  [MSAppDelegateForwarder removeDelegate:self.customAppDelegateMock];

  // When
  [self.originalAppDelegateMock application:self.appMock
      didRegisterForRemoteNotificationsWithDeviceToken:expectedToken];

  // Then
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
}

#if !TARGET_OS_OSX
- (void)testDontForwardOpenURLOnDisable {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL expectedReturnedValue = YES;
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  SEL originalOpenURLiOS42Sel = @selector(application:openURL:sourceApplication:annotation:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalOpenURLiOS42Sel];
  self.originalAppDelegateMock.delegateValidators[NSStringFromSelector(originalOpenURLiOS42Sel)] =
      ^(MSApplication *application, NSURL *url, NSString *sApplication, id annotation) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        [originalCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  NSString *customOpenURLiOS42Str =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:returnedValue:));
  self.customAppDelegateMock.delegateValidators[customOpenURLiOS42Str] =
      ^(__attribute__((unused)) MSApplication *application, __attribute__((unused)) NSURL *url,
        __attribute__((unused)) NSString *sApplication, __attribute__((unused)) id annotation,
        __attribute__((unused)) BOOL returnedValue) {

        // Then
        XCTFail(@"Custom delegate got called but is removed.");
        return expectedReturnedValue;
      };
  [MSAppDelegateForwarder addDelegate:self.customAppDelegateMock];
  MSAppDelegateForwarder.enabled = NO;

  // When
  BOOL returnedValue = [self.originalAppDelegateMock application:self.appMock
                                                         openURL:expectedURL
                                               sourceApplication:nil
                                                      annotation:expectedAnnotation];

  // Then
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
  MSAppDelegateForwarder.enabled = YES;
}
#endif

- (void)testDontForwardDidRegisterForRemoteNotificationWithDeviceTokenOnDisable {

  // If
  NSData *expectedToken = [@"Device token" dataUsingEncoding:NSUTF8StringEncoding];
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  SEL originalDidRegisterForRemoteNotificationWithDeviceTokenSel =
      @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalDidRegisterForRemoteNotificationWithDeviceTokenSel];
  self.originalAppDelegateMock
      .delegateValidators[NSStringFromSelector(originalDidRegisterForRemoteNotificationWithDeviceTokenSel)] =
      ^(MSApplication *application, NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [originalCalledExpectation fulfill];
      };
  NSString *customDidRegisterForRemoteNotificationWithDeviceTokenStr =
      NSStringFromSelector(@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
  self.customAppDelegateMock.delegateValidators[customDidRegisterForRemoteNotificationWithDeviceTokenStr] =
      ^(__attribute__((unused)) MSApplication *application, __attribute__((unused)) NSData *deviceToken) {

        // Then
        XCTFail(@"Custom delegate got called but is removed.");
      };
  [MSAppDelegateForwarder addDelegate:self.customAppDelegateMock];
  MSAppDelegateForwarder.enabled = NO;

  // When
  [self.originalAppDelegateMock application:self.appMock
      didRegisterForRemoteNotificationsWithDeviceToken:expectedToken];

  // Then
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
  MSAppDelegateForwarder.enabled = YES;
}

#if !TARGET_OS_OSX
- (void)testReturnValueChaining {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL initialReturnValue = YES;
  __block BOOL expectedReturnedValue;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  XCTestExpectation *customCalledExpectation1 = [self expectationWithDescription:@"Custom delegate 1 called."];
  XCTestExpectation *customCalledExpectation2 = [self expectationWithDescription:@"Custom delegate 2 called."];
  MSApplication *appMock = self.appMock;
  SEL originalOpenURLiOS42Sel = @selector(application:openURL:sourceApplication:annotation:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalOpenURLiOS42Sel];
  self.originalAppDelegateMock.delegateValidators[NSStringFromSelector(originalOpenURLiOS42Sel)] =
      ^(MSApplication *application, NSURL *url, NSString *sApplication, id annotation) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        [originalCalledExpectation fulfill];
        expectedReturnedValue = initialReturnValue;
        return expectedReturnedValue;
      };
  MSMockCustomAppDelegate *customAppDelegateMock1 = [MSMockCustomAppDelegate new];
  MSMockCustomAppDelegate *customAppDelegateMock2 = [MSMockCustomAppDelegate new];
  NSString *customOpenURLiOS42Str =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:returnedValue:));
  customAppDelegateMock1.delegateValidators[customOpenURLiOS42Str] =
      ^(MSApplication *application, NSURL *url, NSString *sApplication, id annotation, BOOL returnedValue) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        assertThatBool(returnedValue, is(@(expectedReturnedValue)));
        expectedReturnedValue = !returnedValue;
        [customCalledExpectation1 fulfill];
        return expectedReturnedValue;
      };
  customAppDelegateMock2.delegateValidators[customOpenURLiOS42Str] =
      ^(MSApplication *application, NSURL *url, NSString *sApplication, id annotation, BOOL returnedValue) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        assertThatBool(returnedValue, is(@(expectedReturnedValue)));
        expectedReturnedValue = !returnedValue;
        [customCalledExpectation2 fulfill];
        return expectedReturnedValue;
      };
  [MSAppDelegateForwarder addDelegate:customAppDelegateMock1];
  [MSAppDelegateForwarder addDelegate:customAppDelegateMock2];

  // When
  BOOL returnedValue = [self.originalAppDelegateMock application:self.appMock
                                                         openURL:expectedURL
                                               sourceApplication:nil
                                                      annotation:expectedAnnotation];

  // Then
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ originalCalledExpectation, customCalledExpectation1, customCalledExpectation2 ]
                    timeout:1];
}
#endif

#if !TARGET_OS_OSX
- (void)testOpenURLForwardMethodNotImplementedByOriginalDelegate {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary<UIApplicationOpenURLOptionsKey, id> *expectedOptions = @{};
  BOOL expectedReturnedValue = NO;
  MSApplication *appMock = self.appMock;
  XCTestExpectation *customCalledExpectation = [self expectationWithDescription:@"Custom delegate called."];
  SEL originalOpenURLiOS9Sel = @selector(application:openURL:options:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalOpenURLiOS9Sel];
  NSString *customOpenURLiOS9Str = NSStringFromSelector(@selector(application:openURL:options:returnedValue:));
  self.customAppDelegateMock.delegateValidators[customOpenURLiOS9Str] =
      ^(MSApplication *application, NSURL *url, NSDictionary<UIApplicationOpenURLOptionsKey, id> *options,
        BOOL returnedValue) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(options, is(expectedOptions));
        assertThatBool(returnedValue, is(@(expectedReturnedValue)));
        [customCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  [MSAppDelegateForwarder addDelegate:self.customAppDelegateMock];

  // When
  BOOL returnedValue =
      [self.originalAppDelegateMock application:self.appMock openURL:expectedURL options:expectedOptions];

  // Then
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ customCalledExpectation ] timeout:1];
}
#endif

#if TARGET_OS_OSX
- (void)testDidReceiveNotification {

  // If
  id userNotificationUserInfoMock = OCMClassMock([NSUserNotification class]);
  id notificationMock = OCMClassMock([NSNotification class]);
  NSDictionary *notificationUserInfo = @{NSApplicationLaunchUserNotificationKey : userNotificationUserInfoMock};
  NSDictionary *expectedUserInfo = @{ @"aKey" : @"aThingBehindADoor" };
  OCMStub([notificationMock userInfo]).andReturn(notificationUserInfo);
  OCMStub([userNotificationUserInfoMock userInfo]).andReturn(expectedUserInfo);
  XCTestExpectation *customCalledExpectation = [self expectationWithDescription:@"Custom delegate called."];

  // Setup an empty original delegate.
  Class originalAppDelegateClass = [self createClassConformingToProtocol:@protocol(MSApplicationDelegate)];
  id<MSApplicationDelegate> originalAppDelegate = [originalAppDelegateClass new];
  SEL applicationDidFinishLaunchingSel = @selector(applicationDidFinishLaunching:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:applicationDidFinishLaunchingSel];

  // Setup a custom delegate.
  self.customAppDelegateMock.delegateValidators[NSStringFromSelector(applicationDidFinishLaunchingSel)] =
      ^(NSNotification *notification) {

        // Then
        XCTAssertNotNil(notification);
        NSUserNotification *userNotification =
            [notification.userInfo objectForKey:NSApplicationLaunchUserNotificationKey];
        XCTAssertNotNil(userNotification);
        assertThat(userNotification.userInfo, is(expectedUserInfo));
        [customCalledExpectation fulfill];
      };
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [MSAppDelegateForwarder addDelegate:self.customAppDelegateMock];

  // When
  [originalAppDelegate applicationDidFinishLaunching:notificationMock];

  // Then
  [self waitForExpectations:@[ customCalledExpectation ] timeout:1];
}
#else
- (void)testDidReceiveRemoteNotification {

  // If
  // Track fetch result.
  __block UIBackgroundFetchResult forwardedFetchResult = UIBackgroundFetchResultFailed;
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNewData;
  __block BOOL isOriginalHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult fetchResult) {
    forwardedFetchResult = fetchResult;
    isOriginalHandlerCalled = YES;
  };
  NSDictionary *expectedUserInfo = @{ @"aKey" : @"aThingBehindADoor" };
  MSApplication *appMock = self.appMock;
  XCTestExpectation *customCalledExpectation = [self expectationWithDescription:@"Custom delegate called."];

  // Setup an empty original delegate.
  Class originalAppDelegateClass = [self createClassConformingToProtocol:@protocol(MSApplicationDelegate)];
  id<MSApplicationDelegate> originalAppDelegate = [originalAppDelegateClass new];
  SEL didReceiveRemoteNotification1Sel = @selector(application:didReceiveRemoteNotification:);
  SEL didReceiveRemoteNotification2Sel = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didReceiveRemoteNotification1Sel];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didReceiveRemoteNotification2Sel];

  // Setup a custom delegate.
  self.customAppDelegateMock.delegateValidators[NSStringFromSelector(didReceiveRemoteNotification1Sel)] =
      ^(MSApplication *application, NSDictionary *userInfo) {

        // Then
        assertThat(application, is(appMock));
        assertThat(userInfo, is(expectedUserInfo));
      };
  self.customAppDelegateMock.delegateValidators[NSStringFromSelector(didReceiveRemoteNotification2Sel)] =
      ^(MSApplication *application, NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThat(application, is(appMock));
        assertThat(userInfo, is(expectedUserInfo));
        assertThat(fetchHandler, is(fetchHandler));

        // The original handler must only be called after all delegate did run.
        assertThatBool(isOriginalHandlerCalled, isFalse());
        fetchHandler(expectedFetchResult);
        assertThatBool(isOriginalHandlerCalled, isFalse());
        [customCalledExpectation fulfill];
      };
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [MSAppDelegateForwarder addDelegate:self.customAppDelegateMock];

  // When
  [originalAppDelegate application:appMock didReceiveRemoteNotification:expectedUserInfo];
  [originalAppDelegate application:appMock
      didReceiveRemoteNotification:expectedUserInfo
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  [self waitForExpectations:@[ customCalledExpectation ] timeout:1];

  // In the end the completion handler must be called with the forwarded value.
  assertThatBool(isOriginalHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult, equalToInteger(expectedFetchResult));
}
#endif

#pragma mark - Private

- (NSString *)generateClassName {
  return [@"C" stringByAppendingString:MS_UUID_STRING];
}

- (Class)createClassConformingToProtocol:(Protocol *)protocol {
  return [self createClassWithBaseClass:[NSObject class] andConformItToProtocol:protocol];
}

- (Class)createClassWithBaseClass:(Class) class andConformItToProtocol:(Protocol *)protocol {

  // Generate class name to prevent conflicts in runtime added classes.
  const char *name = [[self generateClassName] UTF8String];
  Class newClass = objc_allocateClassPair(class, name, 0);
  if (protocol) {
    class_addProtocol(newClass, protocol);
  }
  objc_registerClassPair(newClass);
  return newClass;
}

- (void)addSelector : (SEL)selector implementation : (id)block types : (const char *)types toClass : (Class) class {
  IMP imp = imp_implementationWithBlock(block);
  class_addMethod(class, selector, imp, types);
}

@end

#pragma clang diagnostic pop
