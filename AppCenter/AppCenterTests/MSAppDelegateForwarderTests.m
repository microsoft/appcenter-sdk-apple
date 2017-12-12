#import <Foundation/Foundation.h>

#import "MSAppDelegateForwarderPrivate.h"
#import "MSAppDelegateUtil.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Application.h"

@interface MSAppDelegateForwarderTest : XCTestCase

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

  // The app delegate forwarder is already set via the load method, reset it for testing.
  [MSAppDelegateForwarder reset];

  // Mock app delegate.
  self.appMock = OCMClassMock([MSApplication class]);
}

- (void)tearDown {
  [MSAppDelegateForwarder reset];
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
  id<MSCustomApplicationDelegate> customDelegate = OCMProtocolMock(@protocol(MSCustomApplicationDelegate));
  [MSAppDelegateForwarder addDelegate:customDelegate];
  NSError *expectedError = [[NSError alloc] initWithDomain:NSItemProviderErrorDomain code:123 userInfo:@{}];

  // App delegate not implementing any selector.
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
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
  originalAppDelegate = [self createOriginalAppDelegateInstance];
  __block BOOL wasCalled = NO;
  id selectorImp = ^{
    wasCalled = YES;
  };
  [self addSelector:selectorToSwizzle implementation:selectorImp toInstance:originalAppDelegate];
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
  id originalBaseAppDelegate = [self createOriginalAppDelegateInstance];
  [self addSelector:selectorToSwizzle implementation:selectorImp toInstance:originalBaseAppDelegate];
  originalAppDelegate = [self createInstanceWithBaseClass:[originalBaseAppDelegate class] andConformItToProtocol:nil];
  wasCalled = NO;
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
  originalBaseAppDelegate = [self createOriginalAppDelegateInstance];
  [self addSelector:selectorToSwizzle implementation:baseSelectorImp toInstance:originalBaseAppDelegate];
  originalAppDelegate = [self createInstanceWithBaseClass:[originalBaseAppDelegate class] andConformItToProtocol:nil];
  [self addSelector:selectorToSwizzle implementation:selectorImp toInstance:originalAppDelegate];
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
  originalAppDelegate = [self createOriginalAppDelegateInstance];
  SEL instancesRespondToSelector = @selector(instancesRespondToSelector:);
  id instancesRespondToSelectorImp = ^{
    return YES;
  };

  // Adding a class method to a class requires its meta class. A meta class is the superclass of a class.
  [self addSelector:instancesRespondToSelector
      implementation:instancesRespondToSelectorImp
             toClass:object_getClass([originalAppDelegate class])];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];

  /*
   * Then
   */

  // Original delegate still responding to selector.
  assertThatBool([[originalAppDelegate class] instancesRespondToSelector:selectorToSwizzle], isTrue());

  // Swizzling did not happened so no method added/replaced for this selector.
  assertThatBool(class_getInstanceMethod([originalAppDelegate class], selectorToSwizzle) == NULL, isTrue());
}

#if !TARGET_OS_OSX
- (void)testSwizzleOriginalOpenURLDelegate {

  /*
   * If
   */

  // Mock a custom app delegate.
  id<MSCustomApplicationDelegate> customDelegate = OCMProtocolMock(@protocol(MSCustomApplicationDelegate));
  [MSAppDelegateForwarder addDelegate:customDelegate];
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedOptions = @{};

  // App delegate not implementing any selector.
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
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
  originalAppDelegate = [self createOriginalAppDelegateInstance];
  __block BOOL wasCalled = NO;
  id selectorImp = ^{
    wasCalled = YES;
    return YES;
  };
  [self addSelector:selectorToSwizzle implementation:selectorImp toInstance:originalAppDelegate];
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
  id originalBaseAppDelegate = [self createOriginalAppDelegateInstance];
  [self addSelector:selectorToSwizzle implementation:selectorImp toInstance:originalBaseAppDelegate];
  originalAppDelegate = [self createInstanceWithBaseClass:[originalBaseAppDelegate class] andConformItToProtocol:nil];
  wasCalled = NO;
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
  originalBaseAppDelegate = [self createOriginalAppDelegateInstance];
  [self addSelector:selectorToSwizzle implementation:baseSelectorImp toInstance:originalBaseAppDelegate];
  originalAppDelegate = [self createInstanceWithBaseClass:[originalBaseAppDelegate class] andConformItToProtocol:nil];
  [self addSelector:selectorToSwizzle implementation:selectorImp toInstance:originalAppDelegate];
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
  originalAppDelegate = [self createOriginalAppDelegateInstance];
  SEL instancesRespondToSelector = @selector(instancesRespondToSelector:);
  id instancesRespondToSelectorImp = ^{
    return YES;
  };

  // Adding a class method to a class requires its meta class.
  [self addSelector:instancesRespondToSelector
      implementation:instancesRespondToSelectorImp
             toClass:object_getClass([originalAppDelegate class])];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:selectorToSwizzle];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];

  /*
   * Then
   */

  // Original delegate still responding to selector.
  assertThatBool([[originalAppDelegate class] instancesRespondToSelector:selectorToSwizzle], isTrue());

  // Swizzling did not happened so no method added/replaced for this selector.
  assertThatBool(class_getInstanceMethod([originalAppDelegate class], selectorToSwizzle) == NULL, isTrue());
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

#if TARGET_OS_IOS
- (void)testWithoutCustomDelegate {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedOptions = @{};
  BOOL expectedReturnedValue = YES;
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  SEL originalOpenURLSel = @selector(application:openURL:options:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalOpenURLSel];
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  id originalOpenURLImp =
      ^(__attribute__((unused)) id itSelf, MSApplication *application, NSURL *url, id options) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(options, is(expectedOptions));
        [originalCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  [self addSelector:originalOpenURLSel implementation:originalOpenURLImp toInstance:originalAppDelegate];

  // When
  BOOL returnedValue = [originalAppDelegate application:self.appMock openURL:expectedURL options:expectedOptions];

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
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  id originalDidRegisterForRemoteNotificationsWithDeviceTokenImp =
      ^(__attribute__((unused)) id itSelf, MSApplication *application, NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [originalCalledExpectation fulfill];
      };
  [self addSelector:originalDidRegisterForRemoteNotificationsWithDeviceTokenSel
      implementation:originalDidRegisterForRemoteNotificationsWithDeviceTokenImp
          toInstance:originalAppDelegate];

  // When
  [originalAppDelegate application:self.appMock didRegisterForRemoteNotificationsWithDeviceToken:expectedToken];

  // Then
  assertThatUnsignedLong(MSAppDelegateForwarder.delegates.count, equalToUnsignedLong(0));
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
}

#if TARGET_OS_IOS
- (void)testWithOneCustomDelegate {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedOptions = @{};
  BOOL expectedReturnedValue = YES;
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  XCTestExpectation *customCalledExpectation = [self expectationWithDescription:@"Custom delegate called."];
  SEL originalOpenURLiOS90Sel = @selector(application:openURL:options:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalOpenURLiOS90Sel];
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  id originalOpenURLiOS90Imp =
      ^(__attribute__((unused)) id itSelf, MSApplication *application, NSURL *url, id options) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(options, is(expectedOptions));
        [originalCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  [self addSelector:originalOpenURLiOS90Sel implementation:originalOpenURLiOS90Imp toInstance:originalAppDelegate];
  SEL customOpenURLiOS90Sel = @selector(application:openURL:options:returnedValue:);
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
  id customOpenURLiOS90Imp = ^(__attribute__((unused)) id itSelf, MSApplication *application, NSURL *url,
                               id options, BOOL returnedValue) {

    // Then
    assertThat(application, is(appMock));
    assertThat(url, is(expectedURL));
    assertThat(options, is(expectedOptions));
    assertThatBool(returnedValue, is(@(expectedReturnedValue)));
    [customCalledExpectation fulfill];
    return expectedReturnedValue;
  };
  [self addSelector:customOpenURLiOS90Sel implementation:customOpenURLiOS90Imp toInstance:customAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];

  // When
  BOOL returnedValue = [originalAppDelegate application:self.appMock openURL:expectedURL options:expectedOptions];

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
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didRegisterNotificationSel];
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  id originalDidRegisterNotificationImp =
      ^(__attribute__((unused)) id itSelf, MSApplication *application, NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [originalCalledExpectation fulfill];
      };
  [self addSelector:didRegisterNotificationSel
      implementation:originalDidRegisterNotificationImp
          toInstance:originalAppDelegate];
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
  id customDidRegisterNotificationImp =
      ^(__attribute__((unused)) id itSelf, MSApplication *application, NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [customCalledExpectation fulfill];
      };
  [self addSelector:didRegisterNotificationSel
      implementation:customDidRegisterNotificationImp
          toInstance:customAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];

  // When
  [originalAppDelegate application:appMock didRegisterForRemoteNotificationsWithDeviceToken:expectedToken];

  // Then
  [self waitForExpectations:@[ originalCalledExpectation, customCalledExpectation ] timeout:1];
}

#if TARGET_OS_IOS
- (void)testWithMultipleCustomOpenURLDelegates {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedOptions = @{};
  BOOL expectedReturnedValue = YES;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  XCTestExpectation *customCalledExpectation1 = [self expectationWithDescription:@"Custom delegate 1 called."];
  XCTestExpectation *customCalledExpectation2 = [self expectationWithDescription:@"Custom delegate 2 called."];
  MSApplication *appMock = self.appMock;
  SEL originalOpenURLiOS90Sel = @selector(application:openURL:options:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalOpenURLiOS90Sel];
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  id originalOpenURLiOS90Imp =
      ^(__attribute__((unused)) id itSelf, MSApplication *application, NSURL *url, id options) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(options, is(expectedOptions));
        [originalCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  [self addSelector:originalOpenURLiOS90Sel implementation:originalOpenURLiOS90Imp toInstance:originalAppDelegate];
  SEL customOpenURLiOS90Sel = @selector(application:openURL:options:returnedValue:);
  id<MSCustomApplicationDelegate> customAppDelegate1 = [self createCustomAppDelegateInstance];
  id customOpenURLiOS90Imp1 = ^(__attribute__((unused)) id itSelf, MSApplication *application, NSURL *url,
                                id options, BOOL returnedValue) {

    // Then
    assertThat(application, is(appMock));
    assertThat(url, is(expectedURL));
    assertThat(options, is(expectedOptions));
    assertThatBool(returnedValue, is(@(expectedReturnedValue)));
    [customCalledExpectation1 fulfill];
    return expectedReturnedValue;
  };
  [self addSelector:customOpenURLiOS90Sel implementation:customOpenURLiOS90Imp1 toInstance:customAppDelegate1];
  id<MSCustomApplicationDelegate> customAppDelegate2 = [self createCustomAppDelegateInstance];
  id customOpenURLiOS90Imp2 = ^(__attribute__((unused)) id itSelf, MSApplication *application, NSURL *url,
                                id options, BOOL returnedValue) {

    // Then
    assertThat(application, is(appMock));
    assertThat(url, is(expectedURL));
    assertThat(options, is(expectedOptions));
    assertThatBool(returnedValue, is(@(expectedReturnedValue)));
    [customCalledExpectation2 fulfill];
    return expectedReturnedValue;
  };
  [self addSelector:customOpenURLiOS90Sel implementation:customOpenURLiOS90Imp2 toInstance:customAppDelegate2];
  [MSAppDelegateForwarder addDelegate:customAppDelegate1];
  [MSAppDelegateForwarder addDelegate:customAppDelegate2];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];

  // When
  BOOL returnedValue = [originalAppDelegate application:self.appMock openURL:expectedURL options:expectedOptions];

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
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  id originalDidRegisterForRemoteNotificationWithDeviceTokenImp =
      ^(__attribute__((unused)) id itSelf, MSApplication *application, NSData *deviceToken) {

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
  id<MSCustomApplicationDelegate> customAppDelegate1 = [self createCustomAppDelegateInstance];
  id customDidRegisterForRemoteNotificationWithDeviceTokenImp1 =
      ^(__attribute__((unused)) id itSelf, MSApplication *application, NSData *deviceToken) {

        // Then
        assertThat(application, is(appMock));
        assertThat(deviceToken, is(expectedToken));
        [customCalledExpectation1 fulfill];
      };
  [self addSelector:customDidRegisterForRemoteNotificationWithDeviceTokenSel
      implementation:customDidRegisterForRemoteNotificationWithDeviceTokenImp1
          toInstance:customAppDelegate1];
  id<MSCustomApplicationDelegate> customAppDelegate2 = [self createCustomAppDelegateInstance];
  id customDidRegisterForRemoteNotificationWithDeviceTokenImp2 =
      ^(__attribute__((unused)) id itSelf, MSApplication *application, NSData *deviceToken) {

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
  [originalAppDelegate application:self.appMock didRegisterForRemoteNotificationsWithDeviceToken:expectedToken];

  // Then
  [self waitForExpectations:@[ originalCalledExpectation, customCalledExpectation1, customCalledExpectation2 ]
                    timeout:1];
}

#if TARGET_OS_IOS
- (void)testWithRemovedCustomOpenURLDelegate {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL expectedReturnedValue = YES;
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  SEL originalOpenURLiOS42Sel = @selector(application:openURL:sourceApplication:annotation:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalOpenURLiOS42Sel];
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  id originalOpenURLiOS42Imp = ^(__attribute__((unused)) id itSelf, MSApplication *application, NSURL *url,
                                 NSString *sApplication, id annotation) {

    // Then
    assertThat(application, is(appMock));
    assertThat(url, is(expectedURL));
    assertThat(sApplication, nilValue());
    assertThat(annotation, is(expectedAnnotation));
    [originalCalledExpectation fulfill];
    return expectedReturnedValue;
  };
  [self addSelector:originalOpenURLiOS42Sel implementation:originalOpenURLiOS42Imp toInstance:originalAppDelegate];
  SEL customOpenURLiOS42Sel = @selector(application:openURL:sourceApplication:annotation:returnedValue:);
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
  id customOpenURLiOS42Imp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSURL *url, __attribute__((unused)) NSString *sApplication,
        __attribute__((unused)) id annotation, __attribute__((unused)) BOOL returnedValue) {

        // Then
        XCTFail(@"Custom delegate got called but is removed.");
        return expectedReturnedValue;
      };
  [self addSelector:customOpenURLiOS42Sel implementation:customOpenURLiOS42Imp toInstance:customAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];
  [MSAppDelegateForwarder removeDelegate:customAppDelegate];

  // When
  BOOL returnedValue = [originalAppDelegate application:self.appMock
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
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  id originalDidRegisterForRemoteNotificationWithDeviceTokenImp =
      ^(__attribute__((unused)) id itSelf, MSApplication *application, NSData *deviceToken) {

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
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
  id customDidRegisterForRemoteNotificationWithDeviceTokenImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
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
  [originalAppDelegate application:self.appMock didRegisterForRemoteNotificationsWithDeviceToken:expectedToken];

  // Then
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
}

#if TARGET_OS_IOS
- (void)testDontForwardOpenURLOnDisable {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL expectedReturnedValue = YES;
  MSApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  SEL originalOpenURLiOS42Sel = @selector(application:openURL:sourceApplication:annotation:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:originalOpenURLiOS42Sel];
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  id originalOpenURLiOS42Imp = ^(__attribute__((unused)) id itSelf, MSApplication *application, NSURL *url,
                                 NSString *sApplication, id annotation) {

    // Then
    assertThat(application, is(appMock));
    assertThat(url, is(expectedURL));
    assertThat(sApplication, nilValue());
    assertThat(annotation, is(expectedAnnotation));
    [originalCalledExpectation fulfill];
    return expectedReturnedValue;
  };
  [self addSelector:originalOpenURLiOS42Sel implementation:originalOpenURLiOS42Imp toInstance:originalAppDelegate];
  SEL customOpenURLiOS42Sel = @selector(application:openURL:sourceApplication:annotation:returnedValue:);
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
  id customOpenURLiOS42Imp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSURL *url, __attribute__((unused)) NSString *sApplication,
        __attribute__((unused)) id annotation, __attribute__((unused)) BOOL returnedValue) {

        // Then
        XCTFail(@"Custom delegate got called but is removed.");
        return expectedReturnedValue;
      };
  [self addSelector:customOpenURLiOS42Sel implementation:customOpenURLiOS42Imp toInstance:customAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];
  MSAppDelegateForwarder.enabled = NO;

  // When
  BOOL returnedValue = [originalAppDelegate application:self.appMock
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
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  id originalDidRegisterForRemoteNotificationWithDeviceTokenImp =
      ^(__attribute__((unused)) id itSelf, MSApplication *application, NSData *deviceToken) {

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
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
  id customDidRegisterForRemoteNotificationWithDeviceTokenImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
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
  [originalAppDelegate application:self.appMock didRegisterForRemoteNotificationsWithDeviceToken:expectedToken];

  // Then
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
  MSAppDelegateForwarder.enabled = YES;
}

#if TARGET_OS_IOS
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
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  id originalOpenURLiOS42Imp = ^(__attribute__((unused)) id itSelf, MSApplication *application, NSURL *url,
                                 NSString *sApplication, id annotation) {

    // Then
    assertThat(application, is(appMock));
    assertThat(url, is(expectedURL));
    assertThat(sApplication, nilValue());
    assertThat(annotation, is(expectedAnnotation));
    [originalCalledExpectation fulfill];
    expectedReturnedValue = initialReturnValue;
    return expectedReturnedValue;
  };
  [self addSelector:originalOpenURLiOS42Sel implementation:originalOpenURLiOS42Imp toInstance:originalAppDelegate];
  SEL customOpenURLiOS42Sel = @selector(application:openURL:sourceApplication:annotation:returnedValue:);
  id<MSCustomApplicationDelegate> customAppDelegate1 = [self createCustomAppDelegateInstance];
  id customOpenURLiOS42Imp1 = ^(__attribute__((unused)) id itSelf, MSApplication *application, NSURL *url,
                                NSString *sApplication, id annotation, BOOL returnedValue) {

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
  [self addSelector:customOpenURLiOS42Sel implementation:customOpenURLiOS42Imp1 toInstance:customAppDelegate1];
  id<MSCustomApplicationDelegate> customAppDelegate2 = [self createCustomAppDelegateInstance];
  id customOpenURLiOS42Imp2 = ^(__attribute__((unused)) id itSelf, MSApplication *application, NSURL *url,
                                NSString *sApplication, id annotation, BOOL returnedValue) {

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
  [self addSelector:customOpenURLiOS42Sel implementation:customOpenURLiOS42Imp2 toInstance:customAppDelegate2];
  [MSAppDelegateForwarder addDelegate:customAppDelegate1];
  [MSAppDelegateForwarder addDelegate:customAppDelegate2];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];

  // When
  BOOL returnedValue = [originalAppDelegate application:self.appMock
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
  NSError *expectedError = [NSError errorWithDomain:@"Don't worry, not a real error." code:404 userInfo:nil];
  MSApplication *appMock = self.appMock;
  XCTestExpectation *customCalledExpectation = [self expectationWithDescription:@"Custom delegate called."];
  SEL didFailToRegisterForNotifSel = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didFailToRegisterForNotifSel];
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
  id didFailToRegisterForNotifImp =
      ^(__attribute__((unused)) id itSelf, MSApplication *application, NSError *error) {

        // Then
        assertThat(application, is(appMock));
        assertThat(error, is(expectedError));
        [customCalledExpectation fulfill];
      };

  [self addSelector:didFailToRegisterForNotifSel
      implementation:didFailToRegisterForNotifImp
          toInstance:customAppDelegate];
  [MSAppDelegateForwarder addDelegate:customAppDelegate];
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];

  // When
  [originalAppDelegate application:self.appMock didFailToRegisterForRemoteNotificationsWithError:expectedError];

  // Then
  [self waitForExpectations:@[ customCalledExpectation ] timeout:1];
}
#endif

#if TARGET_OS_IOS

// TODO: Push doesn't support tvOS. Temporaily disable the test.
- (void)testDidReceiveRemoteNotification {

  // If
  // Track fetch result.
  __block UIBackgroundFetchResult forwardedFetchResult = UIBackgroundFetchResultFailed;
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNewData;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult fetchResult) {
    forwardedFetchResult = fetchResult;
    isExpectedHandlerCalled = YES;
  };
  NSDictionary *expectedUserInfo = @{ @"aKey" : @"aThingBehindADoor" };
  MSApplication *appMock = self.appMock;
  XCTestExpectation *customCalledExpectation = [self expectationWithDescription:@"Custom delegate called."];

  // Setup an empty original delegate.
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel1 = @selector(application:didReceiveRemoteNotification:);
  SEL didReceiveRemoteNotificationSel2 = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel1];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel2];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
  id didReceiveRemoteNotificationImp1 =
      ^(__attribute__((unused)) id itSelf, MSApplication *application, NSDictionary *userInfo) {

        // Then
        assertThat(application, is(appMock));
        assertThat(userInfo, is(expectedUserInfo));
      };
  [self addSelector:didReceiveRemoteNotificationSel1
      implementation:didReceiveRemoteNotificationImp1
          toInstance:customAppDelegate];
  id didReceiveRemoteNotificationImp2 = ^(__attribute__((unused)) id itSelf, MSApplication *application,
                                          NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {

    // Then
    assertThat(application, is(appMock));
    assertThat(userInfo, is(expectedUserInfo));
    assertThat(fetchHandler, is(fetchHandler));

    // The expected handler must only be called after all other handlers did run.
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
  [originalAppDelegate application:appMock didReceiveRemoteNotification:expectedUserInfo];
  [originalAppDelegate application:appMock
      didReceiveRemoteNotification:expectedUserInfo
            fetchCompletionHandler:expectedFetchHandler];

  // Then
  [self waitForExpectations:@[ customCalledExpectation ] timeout:1];

  // In the end the completion handler must be called with the forwarded value.
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult, equalToInteger(expectedFetchResult));
}

- (void)testDidReceiveRemoteNotificationCompletionHandlerImplementedByOriginalAndCustomDelegates {

  // If
  __block UIBackgroundFetchResult forwardedFetchResult = UIBackgroundFetchResultFailed;
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNewData;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult fetchResult) {
    forwardedFetchResult = fetchResult;
    isExpectedHandlerCalled = YES;
  };
  XCTestExpectation *customCalledExpectation = [self expectationWithDescription:@"Custom delegate called."];
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
  id originalDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());
        fetchHandler(expectedFetchResult);
        [originalCalledExpectation fulfill];
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:originalDidReceiveRemoteNotificationImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
  id customDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {

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
  [self waitForExpectations:@[ customCalledExpectation, originalCalledExpectation ] timeout:1];

  // In the end the completion handler must be called with the forwarded value.
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult, equalToInteger(expectedFetchResult));
}

- (void)testDidReceiveRemoteNotificationCompletionHandlerImplementedByOriginalOnly {

  // If
  __block UIBackgroundFetchResult forwardedFetchResult = UIBackgroundFetchResultFailed;
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNewData;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult fetchResult) {
    forwardedFetchResult = fetchResult;
    isExpectedHandlerCalled = YES;
  };
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
  id originalDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());
        fetchHandler(expectedFetchResult);
        [originalCalledExpectation fulfill];
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:originalDidReceiveRemoteNotificationImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
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
  __block UIBackgroundFetchResult forwardedFetchResult = UIBackgroundFetchResultFailed;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult fetchResult) {
    forwardedFetchResult = fetchResult;
    isExpectedHandlerCalled = YES;
  };

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
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
  __block UIBackgroundFetchResult forwardedFetchResult = UIBackgroundFetchResultFailed;
  __block UIBackgroundFetchResult originalFetchResult = UIBackgroundFetchResultNoData;
  __block UIBackgroundFetchResult customFetchResult = UIBackgroundFetchResultNoData;
  __block BOOL isExpectedHandlerCalled = NO;
  __block BOOL isOriginalHandlerCalled = NO;
  __block BOOL isCustomHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult fetchResult) {
    forwardedFetchResult = fetchResult;
    isExpectedHandlerCalled = YES;
  };

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
  id originalDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());
        fetchHandler(originalFetchResult);
        isOriginalHandlerCalled = YES;
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:originalDidReceiveRemoteNotificationImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
  id customDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {

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
  assertThatInteger(forwardedFetchResult, equalToInteger(UIBackgroundFetchResultNoData));

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
  assertThatInteger(forwardedFetchResult, equalToInteger(UIBackgroundFetchResultNewData));

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
  assertThatInteger(forwardedFetchResult, equalToInteger(UIBackgroundFetchResultNewData));

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
  assertThatInteger(forwardedFetchResult, equalToInteger(UIBackgroundFetchResultNewData));

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
  assertThatInteger(forwardedFetchResult, equalToInteger(UIBackgroundFetchResultFailed));

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
  assertThatInteger(forwardedFetchResult, equalToInteger(UIBackgroundFetchResultFailed));
}

- (void)testDidReceiveRemoteNotificationCompletionHandlerOriginalCalledFirst {

  // If
  __block UIBackgroundFetchResult forwardedFetchResult = UIBackgroundFetchResultFailed;
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNewData;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult fetchResult) {
    forwardedFetchResult = fetchResult;
    isExpectedHandlerCalled = YES;
  };
  XCTestExpectation *customCalledExpectation = [self expectationWithDescription:@"Custom delegate called."];
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
  id originalDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());

        // Simulate a background download.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
          [NSThread sleepForTimeInterval:0.001];
          assertThatBool(isExpectedHandlerCalled, isFalse());
          fetchHandler(expectedFetchResult);
          [originalCalledExpectation fulfill];
        });
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:originalDidReceiveRemoteNotificationImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
  id customDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {
        // Simulate a background download.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

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
  [self waitForExpectations:@[ customCalledExpectation, originalCalledExpectation ] timeout:1];

  // In the end the completion handler must be called with the forwarded value.
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult, equalToInteger(expectedFetchResult));
}

- (void)testDidReceiveRemoteNotificationCompletionHandlerCustomCalledFirst {

  // If
  __block UIBackgroundFetchResult forwardedFetchResult = UIBackgroundFetchResultFailed;
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNewData;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult fetchResult) {
    forwardedFetchResult = fetchResult;
    isExpectedHandlerCalled = YES;
  };
  XCTestExpectation *customCalledExpectation = [self expectationWithDescription:@"Custom delegate called."];
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
  id originalDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());

        // Simulate a background download.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
          [NSThread sleepForTimeInterval:0.003];
          assertThatBool(isExpectedHandlerCalled, isFalse());
          fetchHandler(expectedFetchResult);
          [originalCalledExpectation fulfill];
        });
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:originalDidReceiveRemoteNotificationImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup a custom delegate.
  id<MSCustomApplicationDelegate> customAppDelegate = [self createCustomAppDelegateInstance];
  id customDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {
        // Simulate a background download.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

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
  [self waitForExpectations:@[ customCalledExpectation, originalCalledExpectation ] timeout:1];

  // In the end the completion handler must be called with the forwarded value.
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult, equalToInteger(expectedFetchResult));
}

- (void)testDidReceiveRemoteNotificationCompletionHandlerAsyncWithMultipleCustomDelegates {

  // If
  __block UIBackgroundFetchResult forwardedFetchResult = UIBackgroundFetchResultFailed;
  UIBackgroundFetchResult expectedFetchResult = UIBackgroundFetchResultNewData;
  __block BOOL isExpectedHandlerCalled = NO;
  void (^expectedFetchHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult fetchResult) {
    forwardedFetchResult = fetchResult;
    isExpectedHandlerCalled = YES;
  };
  XCTestExpectation *customCalledExpectation1 = [self expectationWithDescription:@"Custom delegate 1 called."];
  XCTestExpectation *customCalledExpectation2 = [self expectationWithDescription:@"Custom delegate 2 called."];
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];

  // Setup the original delegate.
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  SEL didReceiveRemoteNotificationSel = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
  id originalDidReceiveRemoteNotificationImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {

        // Then
        assertThatBool(isExpectedHandlerCalled, isFalse());

        // Simulate a background download.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
          [NSThread sleepForTimeInterval:arc4random_uniform(2) / 100];
          assertThatBool(isExpectedHandlerCalled, isFalse());
          fetchHandler(expectedFetchResult);
          [originalCalledExpectation fulfill];
        });
      };
  [self addSelector:didReceiveRemoteNotificationSel
      implementation:originalDidReceiveRemoteNotificationImp
          toInstance:originalAppDelegate];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:didReceiveRemoteNotificationSel];

  // Setup custom delegates.
  id<MSCustomApplicationDelegate> customAppDelegate1 = [self createCustomAppDelegateInstance];
  id<MSCustomApplicationDelegate> customAppDelegate2 = [self createCustomAppDelegateInstance];
  id customDidReceiveRemoteNotificationImp1 =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {
        // Simulate a background download.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

          // Then
          [NSThread sleepForTimeInterval:arc4random_uniform(2) / 100];
          assertThatBool(isExpectedHandlerCalled, isFalse());
          fetchHandler(expectedFetchResult);
          [customCalledExpectation1 fulfill];
        });
      };
  id customDidReceiveRemoteNotificationImp2 =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) MSApplication *application,
        __attribute__((unused)) NSDictionary *userInfo, void (^fetchHandler)(UIBackgroundFetchResult)) {
        // Simulate a background download.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

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
  [self waitForExpectations:@[ customCalledExpectation1, customCalledExpectation2, originalCalledExpectation ]
                    timeout:1000];

  // In the end the completion handler must be called with the forwarded value.
  assertThatBool(isExpectedHandlerCalled, isTrue());
  assertThatInteger(forwardedFetchResult, equalToInteger(expectedFetchResult));
}

- (void)testDontSwizzleDeprecatedAPIIfNoAPIImplemented {

  /*
   * If
   */

  // Mock a custom app delegate.
  id<MSCustomApplicationDelegate> customDelegate = OCMProtocolMock(@protocol(MSCustomApplicationDelegate));
  [MSAppDelegateForwarder addDelegate:customDelegate];
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  id expectedOptions = @{};
  OCMExpect([customDelegate application:self.appMock openURL:expectedURL options:expectedOptions returnedValue:NO]);

  // App delegate not implementing any API.
  SEL deprecatedSelector = @selector(application:openURL:sourceApplication:annotation:);
  SEL newSelector = @selector(application:openURL:options:);
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:deprecatedSelector];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:newSelector];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock openURL:expectedURL options:expectedOptions];

  /*
   * Then
   */
  assertThatBool([originalAppDelegate respondsToSelector:newSelector], isTrue());
  assertThatBool([originalAppDelegate respondsToSelector:deprecatedSelector], isFalse());
  OCMVerify([customDelegate application:self.appMock openURL:expectedURL options:expectedOptions returnedValue:NO]);
}

- (void)testSwizzleDeprecatedAPIIfNoNewAPIImplemented {

  /*
   * If
   */

  // Mock a custom app delegate.
  id<MSCustomApplicationDelegate> customDelegate = OCMProtocolMock(@protocol(MSCustomApplicationDelegate));
  [MSAppDelegateForwarder addDelegate:customDelegate];
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  id expectedAnotation = @{};
  OCMExpect([customDelegate application:self.appMock
                                openURL:expectedURL
                      sourceApplication:nil
                             annotation:expectedAnotation
                          returnedValue:YES]);

  // App delegate implementing just the deprecated API.
  SEL deprecatedSelector = @selector(application:openURL:sourceApplication:annotation:);
  SEL newSelector = @selector(application:openURL:options:);
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  __block short nbCalls = 0;
  id selectorImp = ^{
    nbCalls++;
    return YES;
  };
  [self addSelector:deprecatedSelector implementation:selectorImp toInstance:originalAppDelegate];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:deprecatedSelector];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:newSelector];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock openURL:expectedURL sourceApplication:nil annotation:expectedAnotation];

  /*
   * Then
   */
  assertThatBool([originalAppDelegate respondsToSelector:newSelector], isFalse());
  assertThatBool([originalAppDelegate respondsToSelector:deprecatedSelector], isTrue());
  assertThatShort(nbCalls, equalToShort(1));
  OCMVerify([customDelegate application:self.appMock
                                openURL:expectedURL
                      sourceApplication:nil
                             annotation:expectedAnotation
                          returnedValue:YES]);
}

- (void)testSwizzleDeprecatedAPIIfJustNewAPIImplemented {

  /*
   * If
   */

  // Mock a custom app delegate.
  id<MSCustomApplicationDelegate> customDelegate = OCMProtocolMock(@protocol(MSCustomApplicationDelegate));
  [MSAppDelegateForwarder addDelegate:customDelegate];
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  id expectedOptions = @{};
  OCMExpect([customDelegate application:self.appMock openURL:expectedURL options:expectedOptions returnedValue:YES]);

  // App delegate implementing just the new API.
  SEL deprecatedSelector = @selector(application:openURL:sourceApplication:annotation:);
  SEL newSelector = @selector(application:openURL:options:);
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  __block short nbCalls = 0;
  id selectorImp = ^{
    nbCalls++;
    return YES;
  };
  [self addSelector:newSelector implementation:selectorImp toInstance:originalAppDelegate];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:deprecatedSelector];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:newSelector];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock openURL:expectedURL options:expectedOptions];

  /*
   * Then
   */
  assertThatBool([originalAppDelegate respondsToSelector:deprecatedSelector], isFalse());
  assertThatBool([originalAppDelegate respondsToSelector:newSelector], isTrue());
  assertThatShort(nbCalls, equalToShort(1));
  OCMVerify([customDelegate application:self.appMock openURL:expectedURL options:expectedOptions returnedValue:YES]);
}

- (void)testSwizzleDeprecatedAPIIfAllAPIsImplemented {

  /*
   * If
   */

  // Mock a custom app delegate.
  id<MSCustomApplicationDelegate> customDelegate = OCMProtocolMock(@protocol(MSCustomApplicationDelegate));
  [MSAppDelegateForwarder addDelegate:customDelegate];
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  id expectedAnotation = @{};
  id expectedOptions = @{};
  OCMExpect([customDelegate application:self.appMock openURL:expectedURL options:expectedOptions returnedValue:YES]);
  OCMExpect([customDelegate application:self.appMock
                                openURL:expectedURL
                      sourceApplication:nil
                             annotation:expectedAnotation
                          returnedValue:YES]);

  // App delegate implementing all the APIs.
  SEL deprecatedSelector = @selector(application:openURL:sourceApplication:annotation:);
  SEL newSelector = @selector(application:openURL:options:);
  id<MSApplicationDelegate> originalAppDelegate = [self createOriginalAppDelegateInstance];
  __block short deprecatedSelectorNbCalls = 0;
  __block short newSelectorNbCalls = 0;
  id deprecatedSelectorImp = ^{
    deprecatedSelectorNbCalls++;
    return YES;
  };
  id newSelectorImp = ^{
    newSelectorNbCalls++;
    return YES;
  };
  [self addSelector:deprecatedSelector implementation:deprecatedSelectorImp toInstance:originalAppDelegate];
  [self addSelector:newSelector implementation:newSelectorImp toInstance:originalAppDelegate];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:deprecatedSelector];
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:newSelector];

  /*
   * When
   */
  [MSAppDelegateForwarder swizzleOriginalDelegate:originalAppDelegate];
  [originalAppDelegate application:self.appMock openURL:expectedURL sourceApplication:nil annotation:expectedAnotation];
  [originalAppDelegate application:self.appMock openURL:expectedURL options:expectedOptions];

  /*
   * Then
   */
  assertThatBool([originalAppDelegate respondsToSelector:newSelector], isTrue());
  assertThatBool([originalAppDelegate respondsToSelector:deprecatedSelector], isTrue());
  assertThatShort(newSelectorNbCalls, equalToShort(1));
  assertThatShort(deprecatedSelectorNbCalls, equalToShort(1));
  OCMVerify([customDelegate application:self.appMock openURL:expectedURL options:expectedOptions returnedValue:YES]);
  OCMVerify([customDelegate application:self.appMock
                                openURL:expectedURL
                      sourceApplication:nil
                             annotation:expectedAnotation
                          returnedValue:YES]);
}

#endif

#pragma mark - Private

- (NSString *)generateClassName {
  return [@"C" stringByAppendingString:MS_UUID_STRING];
}

- (id)createInstanceConformingToProtocol:(Protocol *)protocol {
  return [self createInstanceWithBaseClass:[NSObject class] andConformItToProtocol:protocol];
}

- (id)createInstanceWithBaseClass:(Class) class andConformItToProtocol:(Protocol *)protocol {

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
  return [self createInstanceConformingToProtocol:@protocol(MSCustomApplicationDelegate)];
}

- (id<MSCustomApplicationDelegate>)createCustomAppDelegateInstance {
  return [self createInstanceConformingToProtocol:@protocol(MSCustomApplicationDelegate)];
}

- (void)addSelector:(SEL)selector implementation:(id)block toInstance:(id)instance {
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
