#import "MSAnalytics+Validation.h"
#import "MSAnalytics.h"
#import "MSAnalyticsCategory.h"
#import "MSAnalyticsInternal.h"
#import "MSAnalyticsPrivate.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSAppCenterPrivate.h"
#import "MSChannelGroupDefault.h"
#import "MSChannelUnitDefault.h"
#import "MSConstants+Internal.h"
#import "MSEventLog.h"
#import "MSMockAnalyticsDelegate.h"
#import "MSMockUserDefaults.h"
#import "MSPageLog.h"
#import "MSServiceInternal.h"
#import "MSSessionTrackerPrivate.h"
#import "MSTestFrameworks.h"

static NSString *const kMSTypeEvent = @"event";
static NSString *const kMSTypePage = @"page";
static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSTestTransmissionToken =
    @"AnalyticsTestTransmissionToken";
static NSString *const kMSTestTransmissionToken2 =
    @"AnalyticsTestTransmissionToken2";
static NSString *const kMSAnalyticsServiceName = @"Analytics";

@class MSMockAnalyticsDelegate;

@interface MSAnalyticsTests : XCTestCase <MSAnalyticsDelegate>

@property(nonatomic) MSMockUserDefaults *settingsMock;

@end

@interface MSServiceAbstract ()

- (BOOL)isEnabled;

- (void)setEnabled:(BOOL)enabled;

@end

@interface MSAnalytics ()

- (BOOL)channelUnit:(id<MSChannelUnitProtocol>)channelUnit
    shouldFilterLog:(id<MSLog>)log;

@end

/*
 * FIXME
 * Log manager mock is holding sessionTracker instance even after dealloc and
 * this causes session tracker test failures. There is a PR in OCMock that seems
 * a related issue. https://github.com/erikdoe/ocmock/pull/348 Stopping session
 * tracker after applyEnabledState calls for hack to avoid failures.
 */
@implementation MSAnalyticsTests

- (void)setUp {
  [super setUp];

  // Mock NSUserDefaults
  self.settingsMock = [MSMockUserDefaults new];
}

- (void)tearDown {
  [super tearDown];
  [self.settingsMock stopMocking];

  // Make sure sessionTracker removes all observers.
  [MSAnalytics sharedInstance].sessionTracker = nil;
  [MSAnalytics resetSharedInstance];
}

#pragma mark - Tests

- (void)testvalidateEventName {
  const int maxEventNameLength = 256;

  // If
  NSString *validEventName = @"validEventName";
  NSString *shortEventName = @"e";
  NSString *eventName256 = [@"" stringByPaddingToLength:maxEventNameLength
                                              withString:@"eventName256"
                                         startingAtIndex:0];
  NSString *nullableEventName = nil;
  NSString *emptyEventName = @"";
  NSString *tooLongEventName =
      [@"" stringByPaddingToLength:(maxEventNameLength + 1)
                         withString:@"tooLongEventName"
                    startingAtIndex:0];

  // When
  NSString *valid =
      [[MSAnalytics sharedInstance] validateEventName:validEventName
                                           forLogType:kMSTypeEvent];
  NSString *validShortEventName =
      [[MSAnalytics sharedInstance] validateEventName:shortEventName
                                           forLogType:kMSTypeEvent];
  NSString *validEventName256 =
      [[MSAnalytics sharedInstance] validateEventName:eventName256
                                           forLogType:kMSTypeEvent];
  NSString *validNullableEventName =
      [[MSAnalytics sharedInstance] validateEventName:nullableEventName
                                           forLogType:kMSTypeEvent];
  NSString *validEmptyEventName =
      [[MSAnalytics sharedInstance] validateEventName:emptyEventName
                                           forLogType:kMSTypeEvent];
  NSString *validTooLongEventName =
      [[MSAnalytics sharedInstance] validateEventName:tooLongEventName
                                           forLogType:kMSTypeEvent];

  // Then
  XCTAssertNotNil(valid);
  XCTAssertNotNil(validShortEventName);
  XCTAssertNotNil(validEventName256);
  XCTAssertNil(validNullableEventName);
  XCTAssertNil(validEmptyEventName);
  XCTAssertNotNil(validTooLongEventName);
  XCTAssertEqual([validTooLongEventName length], maxEventNameLength);
}

- (void)testApplyEnabledStateWorks {
  [[MSAnalytics sharedInstance]
        startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                    appSecret:kMSTestAppSecret
      transmissionTargetToken:nil
              fromApplication:YES];

  MSServiceAbstract *service = [MSAnalytics sharedInstance];

  [service setEnabled:YES];
  XCTAssertTrue([service isEnabled]);

  [service setEnabled:NO];
  XCTAssertFalse([service isEnabled]);

  [service setEnabled:YES];
  XCTAssertTrue([service isEnabled]);

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];
}

- (void)testTrackPageCalledWhenAutoPageTrackingEnabled {

  // If
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  id analyticsCategoryMock = OCMClassMock([MSAnalyticsCategory class]);
  NSString *testPageName = @"TestPage";
  OCMStub([analyticsCategoryMock missedPageViewName]).andReturn(testPageName);
  [MSAnalytics setAutoPageTrackingEnabled:YES];
  MSServiceAbstract *service = [MSAnalytics sharedInstance];
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];

  // When
  [[MSAnalytics sharedInstance]
        startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                    appSecret:kMSTestAppSecret
      transmissionTargetToken:nil
              fromApplication:YES];

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  XCTestExpectation *expection =
      [self expectationWithDescription:
                @"Wait for block in applyEnabledState to be dispatched"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expection fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }

                                 // Then
                                 XCTAssertTrue([service isEnabled]);
                                 OCMVerify([analyticsMock trackPage:testPageName
                                                     withProperties:nil]);
                               }];
}

- (void)testSettingDelegateWorks {
  id<MSAnalyticsDelegate> delegateMock =
      OCMProtocolMock(@protocol(MSAnalyticsDelegate));
  [MSAnalytics setDelegate:delegateMock];
  XCTAssertNotNil([MSAnalytics sharedInstance].delegate);
  XCTAssertEqual([MSAnalytics sharedInstance].delegate, delegateMock);
}

- (void)testAnalyticsDelegateWithoutImplementations {

  // If
  MSEventLog *eventLog = OCMClassMock([MSEventLog class]);
  id delegateMock = OCMProtocolMock(@protocol(MSAnalyticsDelegate));
  OCMReject([delegateMock analytics:[MSAnalytics sharedInstance]
                   willSendEventLog:eventLog]);
  OCMReject([delegateMock analytics:[MSAnalytics sharedInstance]
          didSucceedSendingEventLog:eventLog]);
  OCMReject([delegateMock analytics:[MSAnalytics sharedInstance]
             didFailSendingEventLog:eventLog
                          withError:nil]);
  [MSAppCenter sharedInstance].sdkConfigured = NO;
  [MSAppCenter sharedInstance].configuredFromApplication = NO;
  [MSAppCenter start:kMSTestAppSecret withServices:@[ [MSAnalytics class] ]];
  MSChannelUnitDefault *channelMock = [MSAnalytics sharedInstance].channelUnit =
      OCMPartialMock([MSAnalytics sharedInstance].channelUnit);
  OCMStub([channelMock enqueueItem:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        id<MSLog> log = nil;
        [invocation getArgument:&log atIndex:2];
        for (id<MSChannelDelegate> delegate in channelMock.delegates) {

          // Call all channel delegate methods for testing.
          [delegate channel:channelMock willSendLog:log];
          [delegate channel:channelMock didSucceedSendingLog:log];
          [delegate channel:channelMock didFailSendingLog:log withError:nil];
        }
      });

  // When
  [[MSAnalytics sharedInstance].channelUnit enqueueItem:eventLog];

  // Then
  OCMVerifyAll(delegateMock);
}

- (void)testAnalyticsDelegateMethodsAreCalled {

  // If
  [MSAnalytics resetSharedInstance];
  id<MSAnalyticsDelegate> delegateMock =
      OCMProtocolMock(@protocol(MSAnalyticsDelegate));
  [MSAppCenter sharedInstance].sdkConfigured = NO;
  [MSAppCenter sharedInstance].configuredFromApplication = NO;
  [MSAppCenter start:kMSTestAppSecret withServices:@[ [MSAnalytics class] ]];
  MSChannelUnitDefault *channelMock = [MSAnalytics sharedInstance].channelUnit =
      OCMPartialMock([MSAnalytics sharedInstance].channelUnit);
  OCMStub([channelMock enqueueItem:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        id<MSLog> log = nil;
        [invocation getArgument:&log atIndex:2];
        for (id<MSChannelDelegate> delegate in channelMock.delegates) {

          // Call all channel delegate methods for testing.
          [delegate channel:channelMock willSendLog:log];
          [delegate channel:channelMock didSucceedSendingLog:log];
          [delegate channel:channelMock didFailSendingLog:log withError:nil];
        }
      });

  // When
  [[MSAnalytics sharedInstance] setDelegate:delegateMock];
  MSEventLog *eventLog = OCMClassMock([MSEventLog class]);
  [[MSAnalytics sharedInstance].channelUnit enqueueItem:eventLog];

  // Then
  OCMVerify([delegateMock analytics:[MSAnalytics sharedInstance]
                   willSendEventLog:eventLog]);
  OCMVerify([delegateMock analytics:[MSAnalytics sharedInstance]
          didSucceedSendingEventLog:eventLog]);
  OCMVerify([delegateMock analytics:[MSAnalytics sharedInstance]
             didFailSendingEventLog:eventLog
                          withError:nil]);
}

- (void)testAnalyticsLogsVerificationIsCalled {

  // If
  MSEventLog *eventLog = [MSEventLog new];
  eventLog.name = @"test";
  eventLog.properties = @{ @"test" : @"test" };
  MSPageLog *pageLog = [MSPageLog new];
  MSLogWithNameAndProperties *analyticsLog = [MSLogWithNameAndProperties new];
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  OCMExpect([analyticsMock validateLog:eventLog]).andForwardToRealObject();
  OCMExpect([analyticsMock validateEventName:@"test" forLogType:@"event"])
      .andForwardToRealObject();
  OCMExpect([analyticsMock validateProperties:OCMOCK_ANY
                                   forLogName:@"test"
                                      andType:@"event"])
      .andForwardToRealObject();
  OCMExpect([analyticsMock validateLog:pageLog]).andForwardToRealObject();
  OCMExpect([analyticsMock validateEventName:OCMOCK_ANY forLogType:@"page"])
      .andForwardToRealObject();
  OCMReject([analyticsMock validateProperties:OCMOCK_ANY
                                   forLogName:OCMOCK_ANY
                                      andType:@"page"]);
  OCMReject([analyticsMock validateLog:analyticsLog]);

  // When
  [[MSAnalytics sharedInstance] channelUnit:nil shouldFilterLog:eventLog];
  [[MSAnalytics sharedInstance] channelUnit:nil shouldFilterLog:pageLog];
  [[MSAnalytics sharedInstance] channelUnit:nil shouldFilterLog:analyticsLog];

  // Then
  OCMVerifyAll(analyticsMock);
}

- (void)testTrackEventWithoutProperties {

  // If
  __block NSString *name;
  __block NSString *type;
  NSString *expectedName = @"gotACoffee";
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock =
      OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  OCMStub([channelUnitMock
              enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]]])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        type = log.type;
        name = log.name;
      });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  // When
  [MSAnalytics trackEvent:expectedName];

  // Then
  assertThat(type, is(kMSTypeEvent));
  assertThat(name, is(expectedName));
}

- (void)testTrackEventWhenAnalyticsDisabled {

  // If
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  OCMStub([analyticsMock isEnabled]).andReturn(NO);
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  // When
  OCMReject([channelUnitMock enqueueItem:OCMOCK_ANY]);
  [[MSAnalytics sharedInstance] trackEvent:@"Some event"
                            withProperties:nil
                     forTransmissionTarget:nil];

  // Then
  OCMVerifyAll(channelUnitMock);
}

- (void)testTrackEventWithInvalidName {

  // If
  NSString *invalidEventName = nil;
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  // When
  OCMExpect([channelUnitMock enqueueItem:OCMOCK_ANY]);

  // Will be validated in shouldFilterLog callback instead.
  OCMReject([analyticsMock validateEventName:OCMOCK_ANY forLogType:OCMOCK_ANY]);
  OCMReject([analyticsMock validateProperties:OCMOCK_ANY
                                   forLogName:OCMOCK_ANY
                                      andType:OCMOCK_ANY]);
  [[MSAnalytics sharedInstance] trackEvent:invalidEventName
                            withProperties:nil
                     forTransmissionTarget:nil];

  // Then
  OCMVerifyAll(channelUnitMock);
  OCMVerifyAll(analyticsMock);
}

- (void)testTrackEventWithProperties {

  // If
  __block NSString *type;
  __block NSString *name;
  __block NSDictionary<NSString *, NSString *> *properties;
  NSString *expectedName = @"gotACoffee";
  NSDictionary *expectedProperties =
      @{ @"milk" : @"yes",
         @"cookie" : @"of course" };
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  OCMStub([channelUnitMock
              enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]]])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        type = log.type;
        name = log.name;
        properties = log.properties;
      });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  // When
  [MSAnalytics trackEvent:expectedName withProperties:expectedProperties];

  // Then
  assertThat(type, is(kMSTypeEvent));
  assertThat(name, is(expectedName));
  assertThat(properties, is(expectedProperties));
}

- (void)testTrackPageWithoutProperties {

  // If
  __block NSString *name;
  __block NSString *type;
  NSString *expectedName = @"HomeSweetHome";
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock =
      OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  OCMStub([channelUnitMock
              enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]]])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        type = log.type;
        name = log.name;
      });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  // When
  [MSAnalytics trackPage:expectedName];

  // Then
  assertThat(type, is(kMSTypePage));
  assertThat(name, is(expectedName));
}

- (void)testTrackPageWithProperties {

  // If
  __block NSString *type;
  __block NSString *name;
  __block NSDictionary<NSString *, NSString *> *properties;
  NSString *expectedName = @"HomeSweetHome";
  NSDictionary *expectedProperties =
      @{ @"Sofa" : @"yes",
         @"TV" : @"of course" };
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock =
      OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  OCMStub([channelUnitMock
              enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]]])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        type = log.type;
        name = log.name;
        properties = log.properties;
      });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  // When
  [MSAnalytics trackPage:expectedName withProperties:expectedProperties];

  // Then
  assertThat(type, is(kMSTypePage));
  assertThat(name, is(expectedName));
  assertThat(properties, is(expectedProperties));
}

- (void)testTrackPageWhenAnalyticsDisabled {

  // If
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  OCMStub([analyticsMock isEnabled]).andReturn(NO);
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY])
      .andReturn(channelUnitMock);

  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  // When
  OCMReject([channelUnitMock enqueueItem:OCMOCK_ANY]);
  [[MSAnalytics sharedInstance] trackPage:@"Some page" withProperties:nil];

  // Then
  OCMVerifyAll(channelUnitMock);
}

- (void)testTrackPageWithInvalidName {

  // If
  NSString *invalidPageName = nil;
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  // When
  OCMExpect([channelUnitMock enqueueItem:OCMOCK_ANY]);

  // Will be validated in shouldFilterLog callback instead.
  OCMReject([analyticsMock validateEventName:OCMOCK_ANY forLogType:OCMOCK_ANY]);
  OCMReject([analyticsMock validateProperties:OCMOCK_ANY
                                   forLogName:OCMOCK_ANY
                                      andType:OCMOCK_ANY]);
  [[MSAnalytics sharedInstance] trackPage:invalidPageName withProperties:nil];

  // Then
  OCMVerifyAll(channelUnitMock);
  OCMVerifyAll(analyticsMock);
}

- (void)testAutoPageTracking {

  // For now auto page tracking is disabled by default
  XCTAssertFalse([MSAnalytics isAutoPageTrackingEnabled]);

  // When
  [MSAnalytics setAutoPageTrackingEnabled:YES];

  // Then
  XCTAssertTrue([MSAnalytics isAutoPageTrackingEnabled]);

  // When
  [MSAnalytics setAutoPageTrackingEnabled:NO];

  // Then
  XCTAssertFalse([MSAnalytics isAutoPageTrackingEnabled]);
}

- (void)testInitializationPriorityCorrect {
  XCTAssertTrue([[MSAnalytics sharedInstance] initializationPriority] ==
                MSInitializationPriorityDefault);
}

- (void)testServiceNameIsCorrect {
  XCTAssertEqual([MSAnalytics serviceName], kMSAnalyticsServiceName);
}

- (void)testViewWillAppearSwizzlingWithAnalyticsAvailable {

  // If
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  OCMStub([analyticsMock isAutoPageTrackingEnabled]).andReturn(YES);
  OCMStub([analyticsMock isAvailable]).andReturn(YES);
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance]
        startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                    appSecret:kMSTestAppSecret
      transmissionTargetToken:nil
              fromApplication:YES];

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

// When
#if TARGET_OS_OSX
  NSViewController *viewController = [[NSViewController alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
  if ([viewController respondsToSelector:@selector(viewWillAppear)]) {
    [viewController viewWillAppear];
  }
#pragma clang diagnostic pop
#else
  UIViewController *viewController = [[UIViewController alloc] init];
  [viewController viewWillAppear:NO];
#endif

  // Then
  OCMVerify([analyticsMock isAutoPageTrackingEnabled]);
  XCTAssertNil([MSAnalyticsCategory missedPageViewName]);
}

- (void)testViewWillAppearSwizzlingWithAnalyticsNotAvailable {

  // If
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  OCMStub([analyticsMock isAutoPageTrackingEnabled]).andReturn(YES);
  OCMStub([analyticsMock isAvailable]).andReturn(NO);
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance]
        startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                    appSecret:kMSTestAppSecret
      transmissionTargetToken:nil
              fromApplication:YES];

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

// When
#if TARGET_OS_OSX
  NSViewController *viewController = [[NSViewController alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
  if ([viewController respondsToSelector:@selector(viewWillAppear)]) {
    [viewController viewWillAppear];
  }
#pragma clang diagnostic pop
#else
  UIViewController *viewController = [[UIViewController alloc] init];
  [viewController viewWillAppear:NO];
#endif

  // Then
  OCMVerify([analyticsMock isAutoPageTrackingEnabled]);
  XCTAssertNotNil([MSAnalyticsCategory missedPageViewName]);
}

- (void)testViewWillAppearSwizzlingWithShouldTrackPageDisabled {

  // If
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance]
        startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                    appSecret:kMSTestAppSecret
      transmissionTargetToken:nil
              fromApplication:YES];

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  // When
  OCMExpect([analyticsMock isAutoPageTrackingEnabled]).andReturn(YES);
  OCMReject([analyticsMock isAvailable]);
#if TARGET_OS_OSX
  NSPageController *containerController = [[NSPageController alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
  if ([containerController respondsToSelector:@selector(viewWillAppear)]) {
    [containerController viewWillAppear];
  }
#pragma clang diagnostic pop
#else
  UIPageViewController *containerController =
      [[UIPageViewController alloc] init];
  [containerController viewWillAppear:NO];
#endif

  // Then
  OCMVerifyAll(analyticsMock);
}

- (void)testStartWithTransmissionTargetAndAppSecretUsesTransmissionTarget {

  // If
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock =
      OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  __block MSEventLog *log;
  __block int invocations = 0;
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  OCMStub([channelUnitMock
              enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]]])
      .andDo(^(NSInvocation *invocation) {
        ++invocations;
        [invocation getArgument:&log atIndex:2];
      });
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:kMSTestTransmissionToken
                                      fromApplication:YES];

  // When
  [MSAnalytics trackEvent:@"eventName"];

  // Then
  OCMVerify([channelUnitMock enqueueItem:log]);
  XCTAssertTrue(
      [[log transmissionTargetTokens] containsObject:kMSTestTransmissionToken]);
  XCTAssertEqual([[log transmissionTargetTokens] count], (unsigned long)1);
  XCTAssertEqual(invocations, 1);
}

- (void)testStartWithTransmissionTargetWithoutAppSecretUsesTransmissionTarget {

  // If
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock =
      OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  __block MSEventLog *log;
  __block int invocations = 0;
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  OCMStub([channelUnitMock
              enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]]])
      .andDo(^(NSInvocation *invocation) {
        ++invocations;
        [invocation getArgument:&log atIndex:2];
      });
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:nil
                              transmissionTargetToken:kMSTestTransmissionToken
                                      fromApplication:YES];

  // When
  [MSAnalytics trackEvent:@"eventName"];

  // Then
  OCMVerify([channelUnitMock enqueueItem:log]);
  XCTAssertTrue(
      [[log transmissionTargetTokens] containsObject:kMSTestTransmissionToken]);
  XCTAssertEqual([[log transmissionTargetTokens] count], (unsigned long)1);
  XCTAssertEqual(invocations, 1);
}

- (void)testGetTransmissionTargetCreatesTransmissionTargetOnce {

  // When
  MSAnalyticsTransmissionTarget *transmissionTarget1 =
      [MSAnalytics transmissionTargetForToken:kMSTestTransmissionToken];
  MSAnalyticsTransmissionTarget *transmissionTarget2 =
      [MSAnalytics transmissionTargetForToken:kMSTestTransmissionToken];

  // Then
  XCTAssertNotNil(transmissionTarget1);
  XCTAssertEqual(transmissionTarget1, transmissionTarget2);
}

- (void)testEnableStatePropagateToTransmissionTargets {

  // If
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance]
        startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                    appSecret:kMSTestAppSecret
      transmissionTargetToken:nil
              fromApplication:NO];
  MSServiceAbstract *analytics = [MSAnalytics sharedInstance];
  [analytics setEnabled:NO];

  // When

  // Analytics is disabled, targets must match Analytics enabled state.
  MSAnalyticsTransmissionTarget *transmissionTarget =
      [MSAnalytics transmissionTargetForToken:kMSTestTransmissionToken];
  MSAnalyticsTransmissionTarget *transmissionTarget2 =
      [MSAnalytics transmissionTargetForToken:kMSTestTransmissionToken2];

  // Then
  XCTAssertFalse([transmissionTarget isEnabled]);
  XCTAssertFalse([transmissionTarget2 isEnabled]);

  // When

  // Trying re-enabling will fail since Analytics is still disabled.
  [transmissionTarget setEnabled:YES];

  // Then
  XCTAssertFalse([transmissionTarget isEnabled]);
  XCTAssertFalse([transmissionTarget2 isEnabled]);

  // When

  // Enabling Analytics will enable all targets.
  [analytics setEnabled:YES];

  // Then
  XCTAssertTrue([transmissionTarget isEnabled]);
  XCTAssertTrue([transmissionTarget2 isEnabled]);

  // Disabling Analytics will disable all targets.
  [analytics setEnabled:NO];

  // Then
  XCTAssertFalse([transmissionTarget isEnabled]);
  XCTAssertFalse([transmissionTarget2 isEnabled]);
}

- (void)testAppSecretNotRequired {
  XCTAssertFalse([[MSAnalytics sharedInstance] isAppSecretRequired]);
}

- (void)testSessionTrackerStarted {

  // If
  [MSAppCenter resetSharedInstance];

  // When
  [MSAppCenter startFromLibraryWithServices:@[ [MSAnalytics class] ]];

  // Then
  XCTAssertFalse([MSAnalytics sharedInstance].sessionTracker.started);

  // When
  [MSAppCenter start:MS_UUID_STRING withServices:@[ [MSAnalytics class] ]];

  // Then
  XCTAssertTrue([MSAnalytics sharedInstance].sessionTracker.started);

  // FIXME: logManager holds session tracker somehow and it causes other test
  // failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];
}

- (void)testAutoPageTrackingWhenStartedFromLibrary {

  // If
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  id analyticsCategoryMock = OCMClassMock([MSAnalyticsCategory class]);
  NSString *testPageName = @"TestPage";
  OCMStub([analyticsCategoryMock missedPageViewName]).andReturn(testPageName);
  [MSAnalytics setAutoPageTrackingEnabled:YES];
  MSServiceAbstract *service = [MSAnalytics sharedInstance];

  // When
  [[MSAnalytics sharedInstance]
        startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                    appSecret:kMSTestAppSecret
      transmissionTargetToken:nil
              fromApplication:NO];

  // Then
  XCTestExpectation *expection =
      [self expectationWithDescription:
                @"Wait for block in applyEnabledState to be dispatched"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expection fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }

                                 // Then
                                 XCTAssertTrue([service isEnabled]);
                                 OCMReject([analyticsMock trackPage:testPageName
                                                     withProperties:nil]);
                               }];
}

@end
