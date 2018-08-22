#import <Foundation/Foundation.h>

#import "MSPushAppDelegate.h"
#import "MSAppDelegateForwarderPrivate.h"
#import "MSAppDelegateUtil.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Application.h"

@interface MSAppDelegateForwarderTest : XCTestCase

@property(nonatomic) MSApplication *appMock;

@end

/*
 * We use of blocks for test validition but test frameworks contain macro
 * capturing self that we can't avoid.
 * Ignoring retain cycle warning for this test code.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"

// Silence application:openURL:options: availability warning (iOS 9) for the
// whole test.
#pragma clang diagnostic ignored "-Wpartial-availability"

@implementation MSAppDelegateForwarderTest

- (void)setUp {
  [super setUp];

  // The app delegate forwarder is already set via the load method, reset it for
  // testing.
  [MSAppDelegateForwarder reset];

  // Mock app delegate.
  self.appMock = OCMClassMock([MSApplication class]);
}

- (void)tearDown {
  [MSAppDelegateForwarder reset];
  [super tearDown];
}

- (void)testSwizzleOriginalPushDelegate {

  // If
  // Mock a custom app delegate.
  id<MSCustomPushApplicationDelegate> customDelegate =
      OCMProtocolMock(@protocol(MSCustomPushApplicationDelegate));
  [MSAppDelegateForwarder addDelegate:customDelegate];
  NSError *expectedError =
      [[NSError alloc] initWithDomain:NSItemProviderErrorDomain
                                 code:123
                             userInfo:@{}];

  // App delegate not implementing any selector.
  id<MSApplicationDelegate> originalAppDelegate =
      [self createOriginalAppDelegateInstance];
  SEL selectorToSwizzle =
      @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  // When
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock
      didFailToRegisterForRemoteNotificationsWithError:expectedError];

  // Then
  assertThatBool([originalAppDelegate respondsToSelector:selectorToSwizzle],
                 isTrue());
  OCMVerify([customDelegate application:self.appMock
      didFailToRegisterForRemoteNotificationsWithError:expectedError]);

  // If
  // App delegate implementing the selector directly.
  originalAppDelegate = [self createOriginalAppDelegateInstance];
  __block BOOL wasCalled = NO;
  id selectorImp = ^{
    wasCalled = YES;
  };
  [self addSelector:selectorToSwizzle
      implementation:selectorImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  // When
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock
      didFailToRegisterForRemoteNotificationsWithError:expectedError];

  // Then
  assertThatBool([originalAppDelegate respondsToSelector:selectorToSwizzle],
                 isTrue());
  assertThatBool(wasCalled, isTrue());
  OCMVerify([customDelegate application:self.appMock
      didFailToRegisterForRemoteNotificationsWithError:expectedError]);

  // If
  // App delegate implementing the selector indirectly.
  id originalBaseAppDelegate = [self createOriginalAppDelegateInstance];
  [self addSelector:selectorToSwizzle
      implementation:selectorImp
          toInstance:originalBaseAppDelegate];
  originalAppDelegate =
      [self createInstanceWithBaseClass:[originalBaseAppDelegate class]
                 andConformItToProtocol:nil];
  wasCalled = NO;
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  // When
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock
      didFailToRegisterForRemoteNotificationsWithError:expectedError];

  // Then
  assertThatBool([originalAppDelegate respondsToSelector:selectorToSwizzle],
                 isTrue());
  assertThatBool(wasCalled, isTrue());
  OCMVerify([customDelegate application:self.appMock
      didFailToRegisterForRemoteNotificationsWithError:expectedError]);

  // If
  // App delegate implementing the selector directly and indirectly.
  wasCalled = NO;
  __block BOOL baseWasCalled = NO;
  id baseSelectorImp = ^{
    baseWasCalled = YES;
  };
  originalBaseAppDelegate = [self createOriginalAppDelegateInstance];
  [self addSelector:selectorToSwizzle
      implementation:baseSelectorImp
          toInstance:originalBaseAppDelegate];
  originalAppDelegate =
      [self createInstanceWithBaseClass:[originalBaseAppDelegate class]
                 andConformItToProtocol:nil];
  [self addSelector:selectorToSwizzle
      implementation:selectorImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  // When
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock
      didFailToRegisterForRemoteNotificationsWithError:expectedError];

  // Then
  assertThatBool([originalAppDelegate respondsToSelector:selectorToSwizzle],
                 isTrue());
  assertThatBool(wasCalled, isTrue());
  assertThatBool(baseWasCalled, isFalse());
  OCMVerify([customDelegate application:self.appMock
      didFailToRegisterForRemoteNotificationsWithError:expectedError]);

  // If
  // App delegate not implementing any selector still responds to selector.
  originalAppDelegate = [self createOriginalAppDelegateInstance];
  SEL instancesRespondToSelector = @selector(instancesRespondToSelector:);
  id instancesRespondToSelectorImp = ^{
    return YES;
  };

  // Adding a class method to a class requires its meta class. A meta class is
  // the superclass of a class.
  [self addSelector:instancesRespondToSelector
      implementation:instancesRespondToSelectorImp
             toClass:object_getClass([originalAppDelegate class])];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  // When
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];

  // Then
  // Original delegate still responding to selector.
  assertThatBool([[originalAppDelegate class]
                     instancesRespondToSelector:selectorToSwizzle],
                 isTrue());

  // Swizzling did not happened so no method added/replaced for this selector.
  assertThatBool(class_getInstanceMethod([originalAppDelegate class],
                                         selectorToSwizzle) == NULL,
                 isTrue());
}

- (void)testWithMultipleCustomPushDelegates {

  // If
  NSData *expectedToken =
      [@"Device token" dataUsingEncoding:NSUTF8StringEncoding];
  XCTestExpectation *originalCalledExpectation =
      [self expectationWithDescription:@"Original delegate called."];
  XCTestExpectation *customCalledExpectation1 =
      [self expectationWithDescription:@"Custom delegate 1 called."];
  XCTestExpectation *customCalledExpectation2 =
      [self expectationWithDescription:@"Custom delegate 2 called."];
  MSApplication *appMock = self.appMock;
  SEL originalDidRegisterForRemoteNotificationWithDeviceTokenSel =
      @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
  [MSAppDelegateForwarder
      addAppDelegateSelectorToSwizzle:
          originalDidRegisterForRemoteNotificationWithDeviceTokenSel];
  id<MSApplicationDelegate> originalAppDelegate =
      [self createOriginalAppDelegateInstance];
  id originalDidRegisterForRemoteNotificationWithDeviceTokenImp =
      ^(__attribute__((unused)) id itSelf, MSApplication *application,
        NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [originalCalledExpectation fulfill];
      };
  [self addSelector:originalDidRegisterForRemoteNotificationWithDeviceTokenSel
      implementation:originalDidRegisterForRemoteNotificationWithDeviceTokenImp
          toInstance:originalAppDelegate];
  SEL customDidRegisterForRemoteNotificationWithDeviceTokenSel =
      @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
  id<MSCustomApplicationDelegate> customAppDelegate1 =
      [self createCustomAppDelegateInstance];
  id customDidRegisterForRemoteNotificationWithDeviceTokenImp1 =
      ^(__attribute__((unused)) id itSelf, MSApplication *application,
        NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [customCalledExpectation1 fulfill];
      };
  [self addSelector:customDidRegisterForRemoteNotificationWithDeviceTokenSel
      implementation:customDidRegisterForRemoteNotificationWithDeviceTokenImp1
          toInstance:customAppDelegate1];
  id<MSCustomApplicationDelegate> customAppDelegate2 =
      [self createCustomAppDelegateInstance];
  id customDidRegisterForRemoteNotificationWithDeviceTokenImp2 =
      ^(__attribute__((unused)) id itSelf, MSApplication *application,
        NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [customCalledExpectation2 fulfill];
      };
  [self addSelector:customDidRegisterForRemoteNotificationWithDeviceTokenSel
      implementation:customDidRegisterForRemoteNotificationWithDeviceTokenImp2
          toInstance:customAppDelegate2];
  [MSAppDelegateForwarder addDelegate:customAppDelegate1];
  [MSAppDelegateForwarder addDelegate:customAppDelegate2];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];

  // When
  [originalAppDelegate application:self.appMock
      didRegisterForRemoteNotificationsWithDeviceToken:expectedToken];

  // Then
  [self waitForExpectations:@[
    originalCalledExpectation, customCalledExpectation1,
    customCalledExpectation2
  ]
                    timeout:1];
}

- (void)
    testWithRemovedCustomDidRegisterForRemoteNotificationWithDeviceTokenDelegate {

  // If
  NSData *expectedToken =
      [@"Device token" dataUsingEncoding:NSUTF8StringEncoding];
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation =
      [self expectationWithDescription:@"Original delegate called."];
  SEL originalDidRegisterForRemoteNotificationWithDeviceTokenSel =
      @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
  [MSAppDelegateForwarder
      addAppDelegateSelectorToSwizzle:
          originalDidRegisterForRemoteNotificationWithDeviceTokenSel];
  id<MSApplicationDelegate> originalAppDelegate =
      [self createOriginalAppDelegateInstance];
  id originalDidRegisterForRemoteNotificationWithDeviceTokenImp =
      ^(__attribute__((unused)) id itSelf, MSApplication *application,
        NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [originalCalledExpectation fulfill];
      };
  [self addSelector:originalDidRegisterForRemoteNotificationWithDeviceTokenSel
      implementation:originalDidRegisterForRemoteNotificationWithDeviceTokenImp
          toInstance:originalAppDelegate];
  SEL customDidRegisterForRemoteNotificationWithDeviceTokenSel =
      @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
  id<MSCustomApplicationDelegate> customAppDelegate =
      [self createCustomAppDelegateInstance];
  id customDidRegisterForRemoteNotificationWithDeviceTokenImp =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSData *deviceToken) {

        // Then
        XCTFail(@"Custom delegate got called but is removed.");
      };
  [self addSelector:customDidRegisterForRemoteNotificationWithDeviceTokenSel
      implementation:customDidRegisterForRemoteNotificationWithDeviceTokenImp
          toInstance:customAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];
  [MSAppDelegateForwarder removeDelegate:customAppDelegate];

  // When
  [originalAppDelegate application:self.appMock
      didRegisterForRemoteNotificationsWithDeviceToken:expectedToken];

  // Then
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
}

- (void)
    testDontForwardDidRegisterForRemoteNotificationWithDeviceTokenOnDisable {

  // If
  NSData *expectedToken =
      [@"Device token" dataUsingEncoding:NSUTF8StringEncoding];
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation =
      [self expectationWithDescription:@"Original delegate called."];
  SEL originalDidRegisterForRemoteNotificationWithDeviceTokenSel =
      @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
  [MSAppDelegateForwarder
      addAppDelegateSelectorToSwizzle:
          originalDidRegisterForRemoteNotificationWithDeviceTokenSel];
  id<MSApplicationDelegate> originalAppDelegate =
      [self createOriginalAppDelegateInstance];
  id originalDidRegisterForRemoteNotificationWithDeviceTokenImp =
      ^(__attribute__((unused)) id itSelf, MSApplication *application,
        NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [originalCalledExpectation fulfill];
      };
  [self addSelector:originalDidRegisterForRemoteNotificationWithDeviceTokenSel
      implementation:originalDidRegisterForRemoteNotificationWithDeviceTokenImp
          toInstance:originalAppDelegate];
  SEL customDidRegisterForRemoteNotificationWithDeviceTokenSel =
      @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
  id<MSCustomApplicationDelegate> customAppDelegate =
      [self createCustomAppDelegateInstance];
  id customDidRegisterForRemoteNotificationWithDeviceTokenImp =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSData *deviceToken) {

        // Then
        XCTFail(@"Custom delegate got called but is removed.");
      };
  [self addSelector:customDidRegisterForRemoteNotificationWithDeviceTokenSel
      implementation:customDidRegisterForRemoteNotificationWithDeviceTokenImp
          toInstance:customAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];
  MSAppDelegateForwarder.enabled = NO;

  // When
  [originalAppDelegate application:self.appMock
      didRegisterForRemoteNotificationsWithDeviceToken:expectedToken];

  // Then
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
  MSAppDelegateForwarder.enabled = YES;
}

#if TARGET_OS_IOS

// TODO: Push doesn't support tvOS. Temporaily disable the test.
- (void)testDidReceiveRemoteNotification {

  // If
  // Track fetch result.
  __block UIBackgroundFetchResult forwardedFetchResult =
      UIBackgroundFetchResultFailed;
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNewData;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) =
      ^(UIBackgroundFetchResult fetchResult) {
        forwardedFetchResult = fetchResult;
        isExpectedHandlerCalled = YES;
      };
  NSDictionary *expectedUserInfo = @{ @"aKey" : @"aThingBehindADoor" };
  MSApplication *appMock = self.appMock;
  XCTestExpectation *customCalledExpectation =
      [self expectationWithDescription:@"Custom delegate called."];

  // Setup an empty original delegate.
  id<MSApplicationDelegate> originalAppDelegate =
      [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel1 =
      @selector(application:didReceiveRemoteNotification:);
  SEL didReceiveRemoteNotificationSel2 = @selector(application:
                                  didReceiveRemoteNotification:
                                        fetchCompletionHandler:);
  [MSAppDelegateForwarder
      addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel1];
  [MSAppDelegateForwarder
      addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel2];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate =
      [self createCustomAppDelegateInstance];
  id didReceiveRemoteNotificationImp1 =
      ^(__attribute__((unused)) id itSelf, MSApplication *application,
        NSDictionary *userInfo) {

        // Then
        assertThat(application, is(appMock));
        assertThat(userInfo, is(expectedUserInfo));
      };
  [self addSelector:didReceiveRemoteNotificationSel1
      implementation:didReceiveRemoteNotificationImp1
          toInstance:customAppDelegate];
  id didReceiveRemoteNotificationImp2 =
      ^(__attribute__((unused)) id itSelf, MSApplication *application,
        NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThat(application, is(appMock));
        assertThat(userInfo, is(expectedUserInfo));
        assertThat(fetchHandler, is(fetchHandler));

        // The expected handler must only be called after all other handlers did
        // run.
        assertThatBool(isExpectedHandlerCalled, isFalse());
        fetchHandler(expectedFetchResult);
        [customCalledExpectation fulfill];
      };
  [self addSelector:didReceiveRemoteNotificationSel2
      implementation:didReceiveRemoteNotificationImp2
          toInstance:customAppDelegate];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];

  // When
  [originalAppDelegate application:appMock
      didReceiveRemoteNotification:expectedUserInfo];
  [originalAppDelegate application:appMock
      didReceiveRemoteNotification:expectedUserInfo
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  [self waitForExpectations:@[ customCalledExpectation ] timeout:1];

  // In the end the completion handler must be called with the forwarded value.
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult, equalToInteger(expectedFetchResult));
}

- (void)
    testDidReceiveRemoteNotificationCompletionHandlerImplementedByOriginalAndCustomDelegates {

  // If
  __block UIBackgroundFetchResult forwardedFetchResult =
      UIBackgroundFetchResultFailed;
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNewData;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) =
      ^(UIBackgroundFetchResult fetchResult) {
        forwardedFetchResult = fetchResult;
        isExpectedHandlerCalled = YES;
      };
  XCTestExpectation *customCalledExpectation =
      [self expectationWithDescription:@"Custom delegate called."];
  XCTestExpectation *originalCalledExpectation =
      [self expectationWithDescription:@"Original delegate called."];

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate =
      [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:
                                 didReceiveRemoteNotification:
                                       fetchCompletionHandler:);
  id originalDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo,
        void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());
        fetchHandler(expectedFetchResult);
        [originalCalledExpectation fulfill];
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:originalDidReceiveRemoteNotificationImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder
      addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate =
      [self createCustomAppDelegateInstance];
  id customDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo,
        void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());
        fetchHandler(expectedFetchResult);
        [customCalledExpectation fulfill];
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:customDidReceiveRemoteNotificationImp
          toInstance:customAppDelegate];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];

  // When
  [originalAppDelegate application:self.appMock
      didReceiveRemoteNotification:@{}
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  [self waitForExpectations:@[
    customCalledExpectation, originalCalledExpectation
  ]
                    timeout:1];

  // In the end the completion handler must be called with the forwarded value.
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult, equalToInteger(expectedFetchResult));
}

- (void)
    testDidReceiveRemoteNotificationCompletionHandlerImplementedByOriginalOnly {

  // If
  __block UIBackgroundFetchResult forwardedFetchResult =
      UIBackgroundFetchResultFailed;
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNewData;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) =
      ^(UIBackgroundFetchResult fetchResult) {
        forwardedFetchResult = fetchResult;
        isExpectedHandlerCalled = YES;
      };
  XCTestExpectation *originalCalledExpectation =
      [self expectationWithDescription:@"Original delegate called."];

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate =
      [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:
                                 didReceiveRemoteNotification:
                                       fetchCompletionHandler:);
  id originalDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo,
        void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());
        fetchHandler(expectedFetchResult);
        [originalCalledExpectation fulfill];
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:originalDidReceiveRemoteNotificationImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder
      addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate =
      [self createCustomAppDelegateInstance];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];

  // When
  [originalAppDelegate application:self.appMock
      didReceiveRemoteNotification:@{}
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];

  // In the end the completion handler must be called with the forwarded value.
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult, equalToInteger(expectedFetchResult));
}

- (void)testDidReceiveRemoteNotificationCompletionHandlerImplementedByNoOne {

  // If
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNoData;
  __block UIBackgroundFetchResult forwardedFetchResult =
      UIBackgroundFetchResultFailed;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) =
      ^(UIBackgroundFetchResult fetchResult) {
        forwardedFetchResult = fetchResult;
        isExpectedHandlerCalled = YES;
      };

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate =
      [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:
                                 didReceiveRemoteNotification:
                                       fetchCompletionHandler:);
  [MSAppDelegateForwarder
      addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate =
      [self createCustomAppDelegateInstance];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];

  // When
  [originalAppDelegate application:self.appMock
      didReceiveRemoteNotification:@{}
            fetchCompletionHandler:expectedFetchHandler];

  // Then

  // In the end the completion handler must be called with the forwarded value.
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult, equalToInteger(expectedFetchResult));
}

- (void)testDidReceiveRemoteNotificationCompletionHandlerTriage {

  // If
  __block UIBackgroundFetchResult forwardedFetchResult =
      UIBackgroundFetchResultFailed;
  __block UIBackgroundFetchResult originalFetchResult =
      UIBackgroundFetchResultNoData;
  __block UIBackgroundFetchResult customFetchResult =
      UIBackgroundFetchResultNoData;
  __block BOOL isExpectedHandlerCalled = NO;
  __block BOOL isOriginalHandlerCalled = NO;
  __block BOOL isCustomHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) =
      ^(UIBackgroundFetchResult fetchResult) {
        forwardedFetchResult = fetchResult;
        isExpectedHandlerCalled = YES;
      };

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate =
      [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:
                                 didReceiveRemoteNotification:
                                       fetchCompletionHandler:);
  id originalDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo,
        void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());
        fetchHandler(originalFetchResult);
        isOriginalHandlerCalled = YES;
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:originalDidReceiveRemoteNotificationImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder
      addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate =
      [self createCustomAppDelegateInstance];
  id customDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo,
        void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());
        fetchHandler(customFetchResult);
        isCustomHandlerCalled = YES;
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:customDidReceiveRemoteNotificationImp
          toInstance:customAppDelegate];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];

  // When
  [originalAppDelegate application:self.appMock
      didReceiveRemoteNotification:@{}
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatBool(isOriginalHandlerCalled, isTrue());
  assertThatBool(isCustomHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult,
                    equalToInteger(UIBackgroundFetchResultNoData));

  // If
  forwardedFetchResult = UIBackgroundFetchResultFailed;
  originalFetchResult = UIBackgroundFetchResultNewData;
  customFetchResult = UIBackgroundFetchResultNoData;
  isExpectedHandlerCalled = NO;
  isOriginalHandlerCalled = NO;
  isCustomHandlerCalled = NO;

  // When
  [originalAppDelegate application:self.appMock
      didReceiveRemoteNotification:@{}
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatBool(isOriginalHandlerCalled, isTrue());
  assertThatBool(isCustomHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult,
                    equalToInteger(UIBackgroundFetchResultNewData));

  // If
  forwardedFetchResult = UIBackgroundFetchResultFailed;
  originalFetchResult = UIBackgroundFetchResultNewData;
  customFetchResult = UIBackgroundFetchResultNewData;
  isExpectedHandlerCalled = NO;
  isOriginalHandlerCalled = NO;
  isCustomHandlerCalled = NO;

  // When
  [originalAppDelegate application:self.appMock
      didReceiveRemoteNotification:@{}
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatBool(isOriginalHandlerCalled, isTrue());
  assertThatBool(isCustomHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult,
                    equalToInteger(UIBackgroundFetchResultNewData));

  // If
  forwardedFetchResult = UIBackgroundFetchResultNoData;
  originalFetchResult = UIBackgroundFetchResultFailed;
  customFetchResult = UIBackgroundFetchResultNewData;
  isExpectedHandlerCalled = NO;
  isOriginalHandlerCalled = NO;
  isCustomHandlerCalled = NO;

  // When
  [originalAppDelegate application:self.appMock
      didReceiveRemoteNotification:@{}
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatBool(isOriginalHandlerCalled, isTrue());
  assertThatBool(isCustomHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult,
                    equalToInteger(UIBackgroundFetchResultNewData));

  // If
  forwardedFetchResult = UIBackgroundFetchResultNoData;
  originalFetchResult = UIBackgroundFetchResultFailed;
  customFetchResult = UIBackgroundFetchResultFailed;
  isExpectedHandlerCalled = NO;
  isOriginalHandlerCalled = NO;
  isCustomHandlerCalled = NO;

  // When
  [originalAppDelegate application:self.appMock
      didReceiveRemoteNotification:@{}
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatBool(isOriginalHandlerCalled, isTrue());
  assertThatBool(isCustomHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult,
                    equalToInteger(UIBackgroundFetchResultFailed));

  // If
  forwardedFetchResult = UIBackgroundFetchResultNewData;
  originalFetchResult = UIBackgroundFetchResultFailed;
  customFetchResult = UIBackgroundFetchResultNoData;
  isExpectedHandlerCalled = NO;
  isOriginalHandlerCalled = NO;
  isCustomHandlerCalled = NO;

  // When
  [originalAppDelegate application:self.appMock
      didReceiveRemoteNotification:@{}
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatBool(isOriginalHandlerCalled, isTrue());
  assertThatBool(isCustomHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult,
                    equalToInteger(UIBackgroundFetchResultFailed));
}

- (void)testDidReceiveRemoteNotificationCompletionHandlerOriginalCalledFirst {

  // If
  __block UIBackgroundFetchResult forwardedFetchResult =
      UIBackgroundFetchResultFailed;
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNewData;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) =
      ^(UIBackgroundFetchResult fetchResult) {
        forwardedFetchResult = fetchResult;
        isExpectedHandlerCalled = YES;
      };
  XCTestExpectation *customCalledExpectation =
      [self expectationWithDescription:@"Custom delegate called."];
  XCTestExpectation *originalCalledExpectation =
      [self expectationWithDescription:@"Original delegate called."];

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate =
      [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:
                                 didReceiveRemoteNotification:
                                       fetchCompletionHandler:);
  id originalDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo,
        void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());

        // Simulate a background download.
        dispatch_async(
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
              [NSThread sleepForTimeInterval:0.001];
              assertThatBool(isExpectedHandlerCalled, isFalse());
              fetchHandler(expectedFetchResult);
              [originalCalledExpectation fulfill];
            });
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:originalDidReceiveRemoteNotificationImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder
      addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate =
      [self createCustomAppDelegateInstance];
  id customDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo,
        void (^fetchHandler)(UIBackgroundFetchResult)) {
        // Simulate a background download.
        dispatch_async(
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

              // Then
              [NSThread sleepForTimeInterval:0.003];
              assertThatBool(isExpectedHandlerCalled, isFalse());
              fetchHandler(expectedFetchResult);
              [customCalledExpectation fulfill];
            });
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:customDidReceiveRemoteNotificationImp
          toInstance:customAppDelegate];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];

  // When
  [originalAppDelegate application:self.appMock
      didReceiveRemoteNotification:@{}
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  [self waitForExpectations:@[
    customCalledExpectation, originalCalledExpectation
  ]
                    timeout:1];

  // In the end the completion handler must be called with the forwarded value.
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult, equalToInteger(expectedFetchResult));
}

- (void)testDidReceiveRemoteNotificationCompletionHandlerCustomCalledFirst {

  // If
  __block UIBackgroundFetchResult forwardedFetchResult =
      UIBackgroundFetchResultFailed;
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNewData;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) =
      ^(UIBackgroundFetchResult fetchResult) {
        forwardedFetchResult = fetchResult;
        isExpectedHandlerCalled = YES;
      };
  XCTestExpectation *customCalledExpectation =
      [self expectationWithDescription:@"Custom delegate called."];
  XCTestExpectation *originalCalledExpectation =
      [self expectationWithDescription:@"Original delegate called."];

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate =
      [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:
                                 didReceiveRemoteNotification:
                                       fetchCompletionHandler:);
  id originalDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo,
        void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());

        // Simulate a background download.
        dispatch_async(
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
              [NSThread sleepForTimeInterval:0.003];
              assertThatBool(isExpectedHandlerCalled, isFalse());
              fetchHandler(expectedFetchResult);
              [originalCalledExpectation fulfill];
            });
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:originalDidReceiveRemoteNotificationImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder
      addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate =
      [self createCustomAppDelegateInstance];
  id customDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo,
        void (^fetchHandler)(UIBackgroundFetchResult)) {
        // Simulate a background download.
        dispatch_async(
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

              // Then
              [NSThread sleepForTimeInterval:0.001];
              assertThatBool(isExpectedHandlerCalled, isFalse());
              fetchHandler(expectedFetchResult);
              [customCalledExpectation fulfill];
            });
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:customDidReceiveRemoteNotificationImp
          toInstance:customAppDelegate];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];

  // When
  [originalAppDelegate application:self.appMock
      didReceiveRemoteNotification:@{}
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  [self waitForExpectations:@[
    customCalledExpectation, originalCalledExpectation
  ]
                    timeout:1];

  // In the end the completion handler must be called with the forwarded value.
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult, equalToInteger(expectedFetchResult));
}

- (void)
    testDidReceiveRemoteNotificationCompletionHandlerAsyncWithMultipleCustomDelegates {

  // If
  __block UIBackgroundFetchResult forwardedFetchResult =
      UIBackgroundFetchResultFailed;
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNewData;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) =
      ^(UIBackgroundFetchResult fetchResult) {
        forwardedFetchResult = fetchResult;
        isExpectedHandlerCalled = YES;
      };
  XCTestExpectation *customCalledExpectation1 =
      [self expectationWithDescription:@"Custom delegate 1 called."];
  XCTestExpectation *customCalledExpectation2 =
      [self expectationWithDescription:@"Custom delegate 2 called."];
  XCTestExpectation *originalCalledExpectation =
      [self expectationWithDescription:@"Original delegate called."];

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate =
      [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:
                                 didReceiveRemoteNotification:
                                       fetchCompletionHandler:);
  id originalDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo,
        void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());

        // Simulate a background download.
        dispatch_async(
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
              [NSThread sleepForTimeInterval:arc4random_uniform(2) / 100];
              assertThatBool(isExpectedHandlerCalled, isFalse());
              fetchHandler(expectedFetchResult);
              [originalCalledExpectation fulfill];
            });
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:originalDidReceiveRemoteNotificationImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder
      addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup custom delegates.
  id<MSCustomApplicationDelegate> customAppDelegate1 =
      [self createCustomAppDelegateInstance];
  id<MSCustomApplicationDelegate> customAppDelegate2 =
      [self createCustomAppDelegateInstance];
  id customDidReceiveRemoteNotificationImp1 =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo,
        void (^fetchHandler)(UIBackgroundFetchResult)) {
        // Simulate a background download.
        dispatch_async(
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

              // Then
              [NSThread sleepForTimeInterval:arc4random_uniform(2) / 100];
              assertThatBool(isExpectedHandlerCalled, isFalse());
              fetchHandler(expectedFetchResult);
              [customCalledExpectation1 fulfill];
            });
      };
  id customDidReceiveRemoteNotificationImp2 =
      ^(__attribute__((unused)) id itSelf,
        __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo,
        void (^fetchHandler)(UIBackgroundFetchResult)) {
        // Simulate a background download.
        dispatch_async(
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

              // Then
              [NSThread sleepForTimeInterval:arc4random_uniform(2) / 100];
              assertThatBool(isExpectedHandlerCalled, isFalse());
              fetchHandler(expectedFetchResult);
              [customCalledExpectation2 fulfill];
            });
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:customDidReceiveRemoteNotificationImp1
          toInstance:customAppDelegate1];
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:customDidReceiveRemoteNotificationImp2
          toInstance:customAppDelegate2];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate1];
  [MSAppDelegateForwarder addDelegate:customAppDelegate2];

  // When
  [originalAppDelegate application:self.appMock
      didReceiveRemoteNotification:@{}
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  [self waitForExpectations:@[
    customCalledExpectation1, customCalledExpectation2,
    originalCalledExpectation
  ]
                    timeout:1000];

  [self waitForExpectationsWithTimeout:1000
                               handler:^(__unused NSError *error) {

                                 // In the end the completion handler must be
                                 // called with the forwarded value.
                                 assertThatBool(isExpectedHandlerCalled,
                                                isTrue());
                                 assertThatInteger(
                                     forwardedFetchResult,
                                     equalToInteger(expectedFetchResult));
                               }];
}

#endif

#pragma mark - Private

- (NSString *)generateClassName {
  return [@"C" stringByAppendingString:MS_UUID_STRING];
}

- (id)createInstanceConformingToProtocol:(Protocol *)protocol {
  return [self createInstanceWithBaseClass:[NSObject class]
                    andConformItToProtocol:protocol];
}

- (id)createInstanceWithBaseClass:(Class) class
           andConformItToProtocol:(Protocol *)protocol {

  // Generate class name to prevent conflicts in runtime added classes.
  const char *name = [[self generateClassName] UTF8String];
  Class newClass = objc_allocateClassPair(class, name, 0);
  if (protocol) {
    class_addProtocol(newClass, protocol);
  }
  objc_registerClassPair(newClass);
  return [newClass new];
}

    - (id<MSApplicationDelegate>)createOriginalAppDelegateInstance {
  return [self
      createInstanceConformingToProtocol:@protocol(
                                             MSCustomApplicationDelegate)];
}

- (id<MSCustomApplicationDelegate>)createCustomAppDelegateInstance {
  return [self
      createInstanceConformingToProtocol:@protocol(
                                             MSCustomApplicationDelegate)];
}

- (void)addSelector:(SEL)selector
     implementation:(id)block
         toInstance:(id)instance {
  [self addSelector:selector implementation:block toClass:[instance class]];
}

- (void)addSelector:(SEL)selector implementation:(id)block toClass:(id) class {
  Method method = class_getInstanceMethod(class, selector);
  const char *types = method_getTypeEncoding(method);
  IMP imp = imp_implementationWithBlock(block);
  class_addMethod(class, selector, imp, types);
}

@end

#pragma clang diagnostic pop
