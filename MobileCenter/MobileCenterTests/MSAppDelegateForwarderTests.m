#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MSAppDelegateForwarderPrivate.h"
#import "MSAppDelegate.h"
#import "MSMockAppDelegate.h"
#import "MSUtility+Application.h"

@interface MSAppDelegateForwarderTest : XCTestCase

@property(nonatomic) MSMockAppDelegate *appDelegateMock;
@property(nonatomic) UIApplication *appMock;

@end

/*
 * We use of blocks for test validition but test frameworks contain macro capturing self that we can't avoid.
 * Ignoring retain cycle warning for this test code.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"

@implementation MSAppDelegateForwarderTest

- (void)setUp {
  [super setUp];

  // Mock app delegate.
  self.appMock = OCMClassMock([UIApplication class]);
  self.appDelegateMock = [MSMockAppDelegate new];
  id utilMock = OCMClassMock([MSUtility class]);
  OCMStub([utilMock sharedAppDelegate]).andReturn(self.appDelegateMock);
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
  assertThatInteger(MSAppDelegateForwarder.selectorsToSwizzle.count, equalToInteger(currentCount+1));
  assertThatBool([MSAppDelegateForwarder.selectorsToSwizzle containsObject:expectedSelectorStr], isTrue());
  
  // When
  [MSAppDelegateForwarder addAppDelegateSelectorToSwizzle:expectedSelector];
  
  // Then
  assertThatInteger(MSAppDelegateForwarder.selectorsToSwizzle.count, equalToInteger(currentCount+1));
  assertThatBool([MSAppDelegateForwarder.selectorsToSwizzle containsObject:expectedSelectorStr], isTrue());
  [MSAppDelegateForwarder.selectorsToSwizzle removeObject:expectedSelectorStr];
}

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

- (void)testWithoutCustomDelegate {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL expectedReturnedValue = YES;
  UIApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  NSString *originalOpenURLiOS42Selector =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:));
  self.appDelegateMock.originalDelegateValidators[originalOpenURLiOS42Selector] =
      ^(UIApplication *application, NSURL *url, NSString *sApplication, id annotation) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        [originalCalledExpectation fulfill];
        return expectedReturnedValue;
      };

  // When
  BOOL returnedValue = [self.appDelegateMock application:self.appMock
                                                 openURL:expectedURL
                                       sourceApplication:nil
                                              annotation:expectedAnnotation];

  // Then
  assertThatInt(MSAppDelegateForwarder.delegates.count, equalToInt(0));
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
}

- (void)testWithOneCustomDelegate {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL expectedReturnedValue = YES;
  UIApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  XCTestExpectation *customCalledExpectation = [self expectationWithDescription:@"Custom delegate called."];
  NSString *originalOpenURLiOS42Selector =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:));
  self.appDelegateMock.originalDelegateValidators[originalOpenURLiOS42Selector] =
      ^(UIApplication *application, NSURL *url, NSString *sApplication, id annotation) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        [originalCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  NSString *customOpenURLiOS42Selector =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:returnedValue:));
  self.appDelegateMock.customDelegateValidators[customOpenURLiOS42Selector] =
      ^(UIApplication *application, NSURL *url, NSString *sApplication, id annotation, BOOL returnedValue) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        assertThatBool(returnedValue, is(@(expectedReturnedValue)));
        [customCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  [MSAppDelegateForwarder swizzleOriginalDelegate:self.appDelegateMock];
  [MSAppDelegateForwarder addDelegate:self.appDelegateMock];

  // When
  BOOL returnedValue = [self.appDelegateMock application:self.appMock
                                                 openURL:expectedURL
                                       sourceApplication:nil
                                              annotation:expectedAnnotation];

  // Then
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ originalCalledExpectation, customCalledExpectation ] timeout:1];
}

- (void)testWithMultipleCustomDelegates {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL expectedReturnedValue = YES;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  XCTestExpectation *customCalledExpectation1 = [self expectationWithDescription:@"Custom delegate 1 called."];
  XCTestExpectation *customCalledExpectation2 = [self expectationWithDescription:@"Custom delegate 2 called."];
  UIApplication *appMock = self.appMock;
  NSString *originalOpenURLiOS42Selector =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:));
  self.appDelegateMock.originalDelegateValidators[originalOpenURLiOS42Selector] =
      ^(UIApplication *application, NSURL *url, NSString *sApplication, id annotation) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        [originalCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  MSMockAppDelegate *customAppDelegateMock1 = [MSMockAppDelegate new];
  NSString *customOpenURLiOS42Selector =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:returnedValue:));
  customAppDelegateMock1.customDelegateValidators[customOpenURLiOS42Selector] =
      ^(UIApplication *application, NSURL *url, NSString *sApplication, id annotation, BOOL returnedValue) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        assertThatBool(returnedValue, is(@(expectedReturnedValue)));
        [customCalledExpectation1 fulfill];
        return expectedReturnedValue;
      };
  MSMockAppDelegate *customAppDelegateMock2 = [MSMockAppDelegate new];
  customAppDelegateMock2.customDelegateValidators[customOpenURLiOS42Selector] =
      ^(UIApplication *application, NSURL *url, NSString *sApplication, id annotation, BOOL returnedValue) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        assertThatBool(returnedValue, is(@(expectedReturnedValue)));
        [customCalledExpectation2 fulfill];
        return expectedReturnedValue;
      };
  [MSAppDelegateForwarder swizzleOriginalDelegate:customAppDelegateMock1];
  [MSAppDelegateForwarder swizzleOriginalDelegate:customAppDelegateMock2];
  [MSAppDelegateForwarder addDelegate:customAppDelegateMock1];
  [MSAppDelegateForwarder addDelegate:customAppDelegateMock2];

  // When
  BOOL returnedValue = [self.appDelegateMock application:self.appMock
                                                 openURL:expectedURL
                                       sourceApplication:nil
                                              annotation:expectedAnnotation];

  // Then
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ originalCalledExpectation, customCalledExpectation1, customCalledExpectation2 ]
                    timeout:1];
}

- (void)testWithRemovedCustomDelegate {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL expectedReturnedValue = YES;
  UIApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  NSString *originalOpenURLiOS42Selector =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:));
  self.appDelegateMock.originalDelegateValidators[originalOpenURLiOS42Selector] =
      ^(UIApplication *application, NSURL *url, NSString *sApplication, id annotation) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        [originalCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  NSString *customOpenURLiOS42Selector =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:returnedValue:));
  self.appDelegateMock.customDelegateValidators[customOpenURLiOS42Selector] =
      ^(__attribute__((unused))UIApplication *application, __attribute__((unused))NSURL *url, __attribute__((unused))NSString *sApplication, __attribute__((unused))id annotation, __attribute__((unused))BOOL returnedValue) {

        // Then
        XCTFail(@"Custom delegate got called but is removed.");
        return expectedReturnedValue;
      };
  [MSAppDelegateForwarder swizzleOriginalDelegate:self.appDelegateMock];
  [MSAppDelegateForwarder addDelegate:self.appDelegateMock];
  [MSAppDelegateForwarder removeDelegate:self.appDelegateMock];

  // When
  BOOL returnedValue = [self.appDelegateMock application:self.appMock
                                                 openURL:expectedURL
                                       sourceApplication:nil
                                              annotation:expectedAnnotation];

  // Then
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
}

- (void)testDontForwardOnDisable {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL expectedReturnedValue = YES;
  UIApplication *appMock = self.appMock;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  NSString *originalOpenURLiOS42Selector =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:));
  self.appDelegateMock.originalDelegateValidators[originalOpenURLiOS42Selector] =
      ^(UIApplication *application, NSURL *url, NSString *sApplication, id annotation) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        [originalCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  NSString *customOpenURLiOS42Selector =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:returnedValue:));
  self.appDelegateMock.customDelegateValidators[customOpenURLiOS42Selector] =
      ^(__attribute__((unused)) UIApplication *application, __attribute__((unused)) NSURL *url,
        __attribute__((unused)) NSString *sApplication, __attribute__((unused)) id annotation,
        __attribute__((unused)) BOOL returnedValue) {

        // Then
        XCTFail(@"Custom delegate got called but is removed.");
        return expectedReturnedValue;
      };
  [MSAppDelegateForwarder swizzleOriginalDelegate:self.appDelegateMock];
  [MSAppDelegateForwarder addDelegate:self.appDelegateMock];
  MSAppDelegateForwarder.enabled = NO;

  // When
  BOOL returnedValue = [self.appDelegateMock application:self.appMock
                                                 openURL:expectedURL
                                       sourceApplication:nil
                                              annotation:expectedAnnotation];

  // Then
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ originalCalledExpectation ] timeout:1];
  MSAppDelegateForwarder.enabled = YES;
}

- (void)testReturnValueChaining {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary *expectedAnnotation = @{};
  BOOL initialReturnValue = YES;
  __block BOOL expectedReturnedValue;
  XCTestExpectation *originalCalledExpectation = [self expectationWithDescription:@"Original delegate called."];
  XCTestExpectation *customCalledExpectation1 = [self expectationWithDescription:@"Custom delegate 1 called."];
  XCTestExpectation *customCalledExpectation2 = [self expectationWithDescription:@"Custom delegate 2 called."];
  UIApplication *appMock = self.appMock;
  NSString *originalOpenURLiOS42Selector =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:));
  self.appDelegateMock.originalDelegateValidators[originalOpenURLiOS42Selector] =
      ^(UIApplication *application, NSURL *url, NSString *sApplication, id annotation) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(sApplication, nilValue());
        assertThat(annotation, is(expectedAnnotation));
        [originalCalledExpectation fulfill];
        expectedReturnedValue = initialReturnValue;
        return expectedReturnedValue;
      };
  MSMockAppDelegate *customAppDelegateMock1 = [MSMockAppDelegate new];
  MSMockAppDelegate *customAppDelegateMock2 = [MSMockAppDelegate new];
  NSString *customOpenURLiOS42Selector =
      NSStringFromSelector(@selector(application:openURL:sourceApplication:annotation:returnedValue:));
  customAppDelegateMock1.customDelegateValidators[customOpenURLiOS42Selector] =
      ^(UIApplication *application, NSURL *url, NSString *sApplication, id annotation, BOOL returnedValue) {

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
  customAppDelegateMock2.customDelegateValidators[customOpenURLiOS42Selector] =
      ^(UIApplication *application, NSURL *url, NSString *sApplication, id annotation, BOOL returnedValue) {

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
  [MSAppDelegateForwarder swizzleOriginalDelegate:customAppDelegateMock1];
  [MSAppDelegateForwarder swizzleOriginalDelegate:customAppDelegateMock2];
  [MSAppDelegateForwarder addDelegate:customAppDelegateMock1];
  [MSAppDelegateForwarder addDelegate:customAppDelegateMock2];

  // When
  BOOL returnedValue = [self.appDelegateMock application:self.appMock
                                                 openURL:expectedURL
                                       sourceApplication:nil
                                              annotation:expectedAnnotation];

  // Then
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ originalCalledExpectation, customCalledExpectation1, customCalledExpectation2 ]
                    timeout:1];
}

- (void)testForwardMethodNotImplementedByOriginalDelegate {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"https://www.contoso.com/sending-positive-waves"];
  NSDictionary<UIApplicationOpenURLOptionsKey, id> *expectedOptions = @{};
  BOOL expectedReturnedValue = NO;
  UIApplication *appMock = self.appMock;
  XCTestExpectation *customCalledExpectation = [self expectationWithDescription:@"Custom delegate called."];
  NSString *customOpenURLiOS42Selector = NSStringFromSelector(@selector(application:openURL:options:returnedValue:));
  self.appDelegateMock.customDelegateValidators[customOpenURLiOS42Selector] =
      ^(UIApplication *application, NSURL *url, NSDictionary<UIApplicationOpenURLOptionsKey, id> *options,
        BOOL returnedValue) {

        // Then
        assertThat(application, is(appMock));
        assertThat(url, is(expectedURL));
        assertThat(options, is(expectedOptions));
        assertThatBool(returnedValue, is(@(expectedReturnedValue)));
        [customCalledExpectation fulfill];
        return expectedReturnedValue;
      };
  [MSAppDelegateForwarder swizzleOriginalDelegate:self.appDelegateMock];
  [MSAppDelegateForwarder addDelegate:self.appDelegateMock];

  // When
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
  BOOL returnedValue = [self.appDelegateMock application:self.appMock openURL:expectedURL options:expectedOptions];
#pragma clang diagnostic pop

  // Then
  assertThatBool(returnedValue, is(@(expectedReturnedValue)));
  [self waitForExpectations:@[ customCalledExpectation ] timeout:1];
}

#pragma clang diagnostic pop

@end
