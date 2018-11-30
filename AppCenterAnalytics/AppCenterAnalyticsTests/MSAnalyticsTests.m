#import "MSAnalytics+Validation.h"
#import "MSAnalyticsCategory.h"
#import "MSAnalyticsPrivate.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSAppCenterPrivate.h"
#import "MSBooleanTypedProperty.h"
#import "MSChannelUnitDefault.h"
#import "MSConstants+Internal.h"
#import "MSDateTimeTypedProperty.h"
#import "MSDoubleTypedProperty.h"
#import "MSEventLog.h"
#import "MSEventPropertiesInternal.h"
#import "MSLongTypedProperty.h"
#import "MSMockUserDefaults.h"
#import "MSPageLog.h"
#import "MSSessionContextPrivate.h"
#import "MSSessionTrackerPrivate.h"
#import "MSStringTypedProperty.h"
#import "MSTestFrameworks.h"

static NSString *const kMSTypeEvent = @"event";
static NSString *const kMSTypePage = @"page";
static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSTestTransmissionToken = @"AnalyticsTestTransmissionToken";
static NSString *const kMSTestTransmissionToken2 = @"AnalyticsTestTransmissionToken2";
static NSString *const kMSAnalyticsServiceName = @"Analytics";

@class MSMockAnalyticsDelegate;

@interface MSAnalyticsTests : XCTestCase <MSAnalyticsDelegate>

@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) id sessionContextMock;

@end

@interface MSServiceAbstract ()

- (BOOL)isEnabled;

- (void)setEnabled:(BOOL)enabled;

@end

@interface MSAnalytics ()

- (BOOL)channelUnit:(id<MSChannelUnitProtocol>)channelUnit shouldFilterLog:(id<MSLog>)log;

@end

/*
 * FIXME: Log manager mock is holding sessionTracker instance even after dealloc and this causes session tracker test failures. There is a
 * PR in OCMock that seems a related issue. https://github.com/erikdoe/ocmock/pull/348 Stopping session tracker after applyEnabledState
 * calls for hack to avoid failures.
 */
@implementation MSAnalyticsTests

- (void)setUp {
  [super setUp];

  // Mock NSUserDefaults
  self.settingsMock = [MSMockUserDefaults new];

  // Mock session context
  [MSSessionContext resetSharedInstance];
  self.sessionContextMock = OCMClassMock([MSSessionContext class]);
  OCMStub([self.sessionContextMock sharedInstance]).andReturn(self.sessionContextMock);
}

- (void)tearDown {
  [super tearDown];
  [self.settingsMock stopMocking];
  [self.sessionContextMock stopMocking];
  [MSSessionContext resetSharedInstance];

// Make sure sessionTracker removes all observers.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  [MSAnalytics sharedInstance].sessionTracker = nil;
#pragma clang diagnostic pop
  [MSAnalytics resetSharedInstance];
}

#pragma mark - Tests

- (void)testValidateEventName {
  const int maxEventNameLength = 256;

  // If
  NSString *validEventName = @"validEventName";
  NSString *shortEventName = @"e";
  NSString *eventName256 = [@"" stringByPaddingToLength:maxEventNameLength withString:@"eventName256" startingAtIndex:0];
  NSString *nullableEventName = nil;
  NSString *emptyEventName = @"";
  NSString *tooLongEventName = [@"" stringByPaddingToLength:(maxEventNameLength + 1) withString:@"tooLongEventName" startingAtIndex:0];

  // When
  NSString *valid = [[MSAnalytics sharedInstance] validateEventName:validEventName forLogType:kMSTypeEvent];
  NSString *validShortEventName = [[MSAnalytics sharedInstance] validateEventName:shortEventName forLogType:kMSTypeEvent];
  NSString *validEventName256 = [[MSAnalytics sharedInstance] validateEventName:eventName256 forLogType:kMSTypeEvent];
  NSString *validNullableEventName = [[MSAnalytics sharedInstance] validateEventName:nullableEventName forLogType:kMSTypeEvent];
  NSString *validEmptyEventName = [[MSAnalytics sharedInstance] validateEventName:emptyEventName forLogType:kMSTypeEvent];
  NSString *validTooLongEventName = [[MSAnalytics sharedInstance] validateEventName:tooLongEventName forLogType:kMSTypeEvent];

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
  [[MSAnalytics sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
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

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];
}

- (void)testDisablingAnalyticsClearsSessionHistory {
  [[MSAnalytics sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  MSServiceAbstract *service = [MSAnalytics sharedInstance];

  [service setEnabled:NO];
  XCTAssertFalse([service isEnabled]);

  OCMVerify([self.sessionContextMock clearSessionHistoryAndKeepCurrentSession:NO]);
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
  [[MSAnalytics sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for block in applyEnabledState to be dispatched"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }

                                 // Then
                                 XCTAssertTrue([service isEnabled]);
                                 OCMVerify([analyticsMock trackPage:testPageName withProperties:nil]);
                               }];
}

- (void)testSettingDelegateWorks {
  id<MSAnalyticsDelegate> delegateMock = OCMProtocolMock(@protocol(MSAnalyticsDelegate));
  [MSAnalytics setDelegate:delegateMock];
  XCTAssertNotNil([MSAnalytics sharedInstance].delegate);
  XCTAssertEqual([MSAnalytics sharedInstance].delegate, delegateMock);
}

- (void)testAnalyticsDelegateWithoutImplementations {

  // If
  MSEventLog *eventLog = OCMClassMock([MSEventLog class]);
  id delegateMock = OCMProtocolMock(@protocol(MSAnalyticsDelegate));
  OCMReject([delegateMock analytics:[MSAnalytics sharedInstance] willSendEventLog:eventLog]);
  OCMReject([delegateMock analytics:[MSAnalytics sharedInstance] didSucceedSendingEventLog:eventLog]);
  OCMReject([delegateMock analytics:[MSAnalytics sharedInstance] didFailSendingEventLog:eventLog withError:nil]);
  [MSAppCenter sharedInstance].sdkConfigured = NO;
  [MSAppCenter sharedInstance].configuredFromApplication = NO;
  [MSAppCenter start:kMSTestAppSecret withServices:@ [[MSAnalytics class]]];
  MSChannelUnitDefault *channelMock = OCMPartialMock([MSAnalytics sharedInstance].channelUnit);
  [MSAnalytics sharedInstance].channelUnit = channelMock;
  OCMStub([channelMock enqueueItem:OCMOCK_ANY flags:MSFlagsDefault]).andDo(^(NSInvocation *invocation) {
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
  [[MSAnalytics sharedInstance].channelUnit enqueueItem:eventLog flags:MSFlagsDefault];

  // Then
  OCMVerifyAll(delegateMock);
}

- (void)testAnalyticsDelegateMethodsAreCalled {

  // If
  [MSAnalytics resetSharedInstance];
  id<MSAnalyticsDelegate> delegateMock = OCMProtocolMock(@protocol(MSAnalyticsDelegate));
  [MSAppCenter sharedInstance].sdkConfigured = NO;
  [MSAppCenter sharedInstance].configuredFromApplication = NO;
  [MSAppCenter start:kMSTestAppSecret withServices:@ [[MSAnalytics class]]];
  MSChannelUnitDefault *channelMock = OCMPartialMock([MSAnalytics sharedInstance].channelUnit);
  [MSAnalytics sharedInstance].channelUnit = channelMock;
  OCMStub([channelMock enqueueItem:OCMOCK_ANY flags:MSFlagsDefault]).andDo(^(NSInvocation *invocation) {
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
  [[MSAnalytics sharedInstance].channelUnit enqueueItem:eventLog flags:MSFlagsDefault];

  // Then
  OCMVerify([delegateMock analytics:[MSAnalytics sharedInstance] willSendEventLog:eventLog]);
  OCMVerify([delegateMock analytics:[MSAnalytics sharedInstance] didSucceedSendingEventLog:eventLog]);
  OCMVerify([delegateMock analytics:[MSAnalytics sharedInstance] didFailSendingEventLog:eventLog withError:nil]);
}

- (void)testAnalyticsLogsVerificationIsCalled {

  // If
  MSEventLog *eventLog = [MSEventLog new];
  eventLog.name = @"test";
  eventLog.properties = @{@"test" : @"test"};
  MSPageLog *pageLog = [MSPageLog new];
  MSLogWithNameAndProperties *analyticsLog = [MSLogWithNameAndProperties new];
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  OCMExpect([analyticsMock validateLog:eventLog]).andForwardToRealObject();
  OCMExpect([analyticsMock validateEventName:@"test" forLogType:@"event"]).andForwardToRealObject();
  OCMExpect([analyticsMock validateProperties:OCMOCK_ANY forLogName:@"test" andType:@"event"]).andForwardToRealObject();
  OCMExpect([analyticsMock validateLog:pageLog]).andForwardToRealObject();
  OCMExpect([analyticsMock validateEventName:OCMOCK_ANY forLogType:@"page"]).andForwardToRealObject();
  OCMReject([analyticsMock validateProperties:OCMOCK_ANY forLogName:OCMOCK_ANY andType:@"page"]);
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
  id<MSChannelUnitProtocol> channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]] flags:MSFlagsDefault])
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

  // When
  [MSAnalytics trackEvent:expectedName];

  // Then
  assertThat(type, is(kMSTypeEvent));
  assertThat(name, is(expectedName));
}

- (void)testTrackEventWithPropertiesNilWhenAnalyticsDisabled {

  // If
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  OCMStub([analyticsMock isEnabled]).andReturn(NO);
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  OCMReject([channelUnitMock enqueueItem:OCMOCK_ANY flags:MSFlagsDefault]);
  [[MSAnalytics sharedInstance] trackEvent:@"Some event" withProperties:nil forTransmissionTarget:nil flags:MSFlagsDefault];

  // Then
  OCMVerifyAll(channelUnitMock);
}

- (void)testTrackEventWithTypedPropertiesNilWhenAnalyticsDisabled {

  // If
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  OCMStub([analyticsMock isEnabled]).andReturn(NO);
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  OCMReject([channelUnitMock enqueueItem:OCMOCK_ANY flags:MSFlagsDefault]);
  [[MSAnalytics sharedInstance] trackEvent:@"Some event" withTypedProperties:nil forTransmissionTarget:nil flags:MSFlagsDefault];

  // Then
  OCMVerifyAll(channelUnitMock);
}

- (void)testTrackEventWithPropertiesNilWhenTransmissionTargetDisabled {

  // If
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  OCMReject([channelUnitMock enqueueItem:OCMOCK_ANY flags:MSFlagsDefault]);
  MSAnalyticsTransmissionTarget *target = [MSAnalytics transmissionTargetForToken:@"test"];
  [target setEnabled:NO];
  [[MSAnalytics sharedInstance] trackEvent:@"Some event" withProperties:nil forTransmissionTarget:target flags:MSFlagsDefault];

  // Then
  OCMVerifyAll(channelUnitMock);

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];
}

- (void)testTrackEventSetsTagWhenTransmissionTargetProvided {

  // If
  __block NSObject *tag;
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSEventLog class]] flags:MSFlagsDefault]).andDo(^(NSInvocation *invocation) {
    MSEventLog *log;
    [invocation getArgument:&log atIndex:2];
    tag = log.tag;
  });

  // When
  MSAnalyticsTransmissionTarget *target = [MSAnalytics transmissionTargetForToken:@"test"];
  [[MSAnalytics sharedInstance] trackEvent:@"Some event" withProperties:nil forTransmissionTarget:target flags:MSFlagsDefault];

  // Then
  XCTAssertEqualObjects(tag, target);
}

- (void)testTrackEventDoesNotSetUserIdForAppCenter {

  // If
  __block MSEventLog *log;
  [MSAppCenter setUserId:@"c:test"];
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSEventLog class]] flags:MSFlagsDefault]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&log atIndex:2];
  });

  // When
  [MSAnalytics trackEvent:@"Some event"];

  // Then
  XCTAssertNotNil(log);
  XCTAssertNil(log.userId);
}

- (void)testTrackEventWithTypedPropertiesNilWhenTransmissionTargetDisabled {

  // If
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  OCMReject([channelUnitMock enqueueItem:OCMOCK_ANY flags:MSFlagsDefault]);
  MSAnalyticsTransmissionTarget *target = [MSAnalytics transmissionTargetForToken:@"test"];
  [target setEnabled:NO];
  [[MSAnalytics sharedInstance] trackEvent:@"Some event" withTypedProperties:nil forTransmissionTarget:target flags:MSFlagsDefault];

  // Then
  OCMVerifyAll(channelUnitMock);

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];
}

- (void)testTrackEventWithPropertiesNilAndInvalidName {

  // If
  NSString *invalidEventName = nil;
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  OCMExpect([channelUnitMock enqueueItem:OCMOCK_ANY flags:MSFlagsDefault]);

  // Will be validated in shouldFilterLog callback instead.
  OCMReject([analyticsMock validateEventName:OCMOCK_ANY forLogType:OCMOCK_ANY]);
  OCMReject([analyticsMock validateProperties:OCMOCK_ANY forLogName:OCMOCK_ANY andType:OCMOCK_ANY]);
  [[MSAnalytics sharedInstance] trackEvent:invalidEventName withProperties:nil forTransmissionTarget:nil flags:MSFlagsDefault];

  // Then
  OCMVerifyAll(channelUnitMock);
  OCMVerifyAll(analyticsMock);
}

- (void)testTrackEventWithTypedPropertiesNilAndInvalidName {

  // If
  NSString *invalidEventName = nil;
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  OCMExpect([channelUnitMock enqueueItem:OCMOCK_ANY flags:MSFlagsDefault]);

  // Will be validated in shouldFilterLog callback instead.
  OCMReject([analyticsMock validateEventName:OCMOCK_ANY forLogType:OCMOCK_ANY]);
  OCMReject([analyticsMock validateProperties:OCMOCK_ANY forLogName:OCMOCK_ANY andType:OCMOCK_ANY]);
  [[MSAnalytics sharedInstance] trackEvent:invalidEventName withTypedProperties:nil forTransmissionTarget:nil flags:MSFlagsDefault];

  // Then
  OCMVerifyAll(channelUnitMock);
  OCMVerifyAll(analyticsMock);
}

- (void)testTrackEventWithProperties {

  // If
  __block NSString *type;
  __block NSString *name;
  __block MSEventProperties *eventProperties;
  NSString *expectedName = @"gotACoffee";
  NSDictionary *expectedProperties = @{@"milk" : @"yes", @"cookie" : @"of course"};
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSEventLog class]] flags:MSFlagsDefault]).andDo(^(NSInvocation *invocation) {
    MSEventLog *log;
    [invocation getArgument:&log atIndex:2];
    type = log.type;
    name = log.name;
    eventProperties = log.typedProperties;
  });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  [MSAnalytics trackEvent:expectedName withProperties:expectedProperties];

  // Then
  assertThat(type, is(kMSTypeEvent));
  assertThat(name, is(expectedName));
  for (MSTypedProperty *typedProperty in [eventProperties.properties objectEnumerator]) {
    assertThat(typedProperty, isA([MSStringTypedProperty class]));
    MSStringTypedProperty *stringTypedProperty = (MSStringTypedProperty *)typedProperty;
    assertThat(stringTypedProperty.value, equalTo(expectedProperties[stringTypedProperty.name]));
  }
  XCTAssertEqual([expectedProperties count], [eventProperties.properties count]);
}

- (void)testTrackEventWithTypedProperties {

  // If
  __block NSString *type;
  __block NSString *name;
  __block MSEventProperties *eventProperties;
  MSEventProperties *expectedProperties = [MSEventProperties new];
  [expectedProperties setString:@"string" forKey:@"stringKey"];
  [expectedProperties setBool:YES forKey:@"boolKey"];
  [expectedProperties setDate:[NSDate new] forKey:@"dateKey"];
  [expectedProperties setInt64:123 forKey:@"longKey"];
  [expectedProperties setDouble:1.23e2 forKey:@"doubleKey"];
  NSString *expectedName = @"gotACoffee";
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSEventLog class]] flags:MSFlagsDefault]).andDo(^(NSInvocation *invocation) {
    MSEventLog *log;
    [invocation getArgument:&log atIndex:2];
    type = log.type;
    name = log.name;
    eventProperties = log.typedProperties;
  });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  [MSAnalytics trackEvent:expectedName withTypedProperties:expectedProperties];

  // Then
  assertThat(type, is(kMSTypeEvent));
  assertThat(name, is(expectedName));

  for (NSString *propertyKey in eventProperties.properties) {
    MSTypedProperty *typedProperty = eventProperties.properties[propertyKey];
    XCTAssertEqual(typedProperty.name, propertyKey);
    if ([typedProperty isKindOfClass:[MSBooleanTypedProperty class]]) {
      MSBooleanTypedProperty *expectedProperty = (MSBooleanTypedProperty *)expectedProperties.properties[propertyKey];
      MSBooleanTypedProperty *property = (MSBooleanTypedProperty *)eventProperties.properties[propertyKey];
      XCTAssertEqual(property.value, expectedProperty.value);
    } else if ([typedProperty isKindOfClass:[MSDoubleTypedProperty class]]) {
      MSDoubleTypedProperty *expectedProperty = (MSDoubleTypedProperty *)expectedProperties.properties[propertyKey];
      MSDoubleTypedProperty *property = (MSDoubleTypedProperty *)eventProperties.properties[propertyKey];
      XCTAssertEqual(property.value, expectedProperty.value);
    } else if ([typedProperty isKindOfClass:[MSLongTypedProperty class]]) {
      MSLongTypedProperty *expectedProperty = (MSLongTypedProperty *)expectedProperties.properties[propertyKey];
      MSLongTypedProperty *property = (MSLongTypedProperty *)eventProperties.properties[propertyKey];
      XCTAssertEqual(property.value, expectedProperty.value);
    } else if ([typedProperty isKindOfClass:[MSStringTypedProperty class]]) {
      MSStringTypedProperty *expectedProperty = (MSStringTypedProperty *)expectedProperties.properties[propertyKey];
      MSStringTypedProperty *property = (MSStringTypedProperty *)eventProperties.properties[propertyKey];
      XCTAssertEqualObjects(property.value, expectedProperty.value);
    } else if ([typedProperty isKindOfClass:[MSDateTimeTypedProperty class]]) {
      MSDateTimeTypedProperty *expectedProperty = (MSDateTimeTypedProperty *)expectedProperties.properties[propertyKey];
      MSDateTimeTypedProperty *property = (MSDateTimeTypedProperty *)eventProperties.properties[propertyKey];
      XCTAssertEqual(property.value, expectedProperty.value);
    }
    [expectedProperties.properties removeObjectForKey:propertyKey];
  }
  XCTAssertEqual([expectedProperties.properties count], 0);
}

- (void)testTrackEventWithPropertiesWithNormalPersistenceFlag {

  // If
  __block NSString *actualType;
  __block NSString *actualName;
  __block MSFlags actualFlags;
  NSString *expectedName = @"gotACoffee";
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([[channelUnitMock ignoringNonObjectArgs] enqueueItem:[OCMArg isKindOfClass:[MSEventLog class]] flags:(MSFlags)0])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        actualType = log.type;
        actualName = log.name;
        MSFlags flags;
        [invocation getArgument:&flags atIndex:3];
        actualFlags = flags;
      });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  [MSAnalytics trackEvent:expectedName withProperties:nil flags:MSFlagsPersistenceNormal];

  // Then
  XCTAssertEqual(actualType, kMSTypeEvent);
  XCTAssertEqual(actualName, expectedName);
  XCTAssertEqual(actualFlags, MSFlagsPersistenceNormal);
}

- (void)testTrackEventWithPropertiesWithCriticalPersistenceFlag {

  // If
  __block NSString *actualType;
  __block NSString *actualName;
  __block MSFlags actualFlags;
  NSString *expectedName = @"gotACoffee";
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([[channelUnitMock ignoringNonObjectArgs] enqueueItem:[OCMArg isKindOfClass:[MSEventLog class]] flags:(MSFlags)0])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        actualType = log.type;
        actualName = log.name;
        MSFlags flags;
        [invocation getArgument:&flags atIndex:3];
        actualFlags = flags;
      });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  [MSAnalytics trackEvent:expectedName withProperties:nil flags:MSFlagsPersistenceCritical];

  // Then
  XCTAssertEqual(actualType, kMSTypeEvent);
  XCTAssertEqual(actualName, expectedName);
  XCTAssertEqual(actualFlags, MSFlagsPersistenceCritical);
}

- (void)testTrackEventWithPropertiesWithInvalidFlag {

  // If
  __block NSString *actualType;
  __block NSString *actualName;
  __block MSFlags actualFlags;
  NSString *expectedName = @"gotACoffee";
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([[channelUnitMock ignoringNonObjectArgs] enqueueItem:[OCMArg isKindOfClass:[MSEventLog class]] flags:(MSFlags)0])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        actualType = log.type;
        actualName = log.name;
        MSFlags flags;
        [invocation getArgument:&flags atIndex:3];
        actualFlags = flags;
      });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  [MSAnalytics trackEvent:expectedName withProperties:nil flags:42];

  // Then
  XCTAssertEqual(actualType, kMSTypeEvent);
  XCTAssertEqual(actualName, expectedName);
  XCTAssertEqual(actualFlags, MSFlagsPersistenceNormal);
}

- (void)testTrackEventWithTypedPropertiesWithNormalPersistenceFlag {

  // If
  __block NSString *actualType;
  __block NSString *actualName;
  __block MSFlags actualFlags;
  NSString *expectedName = @"gotACoffee";
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([[channelUnitMock ignoringNonObjectArgs] enqueueItem:[OCMArg isKindOfClass:[MSEventLog class]] flags:(MSFlags)0])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        actualType = log.type;
        actualName = log.name;
        MSFlags flags;
        [invocation getArgument:&flags atIndex:3];
        actualFlags = flags;
      });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  [MSAnalytics trackEvent:expectedName withTypedProperties:nil flags:MSFlagsPersistenceNormal];

  // Then
  XCTAssertEqual(actualType, kMSTypeEvent);
  XCTAssertEqual(actualName, expectedName);
  XCTAssertEqual(actualFlags, MSFlagsPersistenceNormal);
}

- (void)testTrackEventWithTypedPropertiesWithCriticalPersistenceFlag {

  // If
  __block NSString *actualType;
  __block NSString *actualName;
  __block MSFlags actualFlags;
  NSString *expectedName = @"gotACoffee";
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([[channelUnitMock ignoringNonObjectArgs] enqueueItem:[OCMArg isKindOfClass:[MSEventLog class]] flags:(MSFlags)0])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        actualType = log.type;
        actualName = log.name;
        MSFlags flags;
        [invocation getArgument:&flags atIndex:3];
        actualFlags = flags;
      });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  [MSAnalytics trackEvent:expectedName withTypedProperties:nil flags:MSFlagsPersistenceCritical];

  // Then
  XCTAssertEqual(actualType, kMSTypeEvent);
  XCTAssertEqual(actualName, expectedName);
  XCTAssertEqual(actualFlags, MSFlagsPersistenceCritical);
}

- (void)testTrackEventWithTypedPropertiesWithInvalidFlag {

  // If
  __block NSString *actualType;
  __block NSString *actualName;
  __block MSFlags actualFlags;
  NSString *expectedName = @"gotACoffee";
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([[channelUnitMock ignoringNonObjectArgs] enqueueItem:[OCMArg isKindOfClass:[MSEventLog class]] flags:(MSFlags)0])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        actualType = log.type;
        actualName = log.name;
        MSFlags flags;
        [invocation getArgument:&flags atIndex:3];
        actualFlags = flags;
      });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  [MSAnalytics trackEvent:expectedName withTypedProperties:nil flags:42];

  // Then
  XCTAssertEqual(actualType, kMSTypeEvent);
  XCTAssertEqual(actualName, expectedName);
  XCTAssertEqual(actualFlags, MSFlagsPersistenceNormal);
}

- (void)testTrackPageWithoutProperties {

  // If
  __block NSString *name;
  __block NSString *type;
  NSString *expectedName = @"HomeSweetHome";
  id<MSChannelUnitProtocol> channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]] flags:MSFlagsDefault])
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
  NSDictionary *expectedProperties = @{@"Sofa" : @"yes", @"TV" : @"of course"};
  id<MSChannelUnitProtocol> channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]] flags:MSFlagsDefault])
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
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);

  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  OCMReject([channelUnitMock enqueueItem:OCMOCK_ANY flags:MSFlagsDefault]);
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
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  OCMExpect([channelUnitMock enqueueItem:OCMOCK_ANY flags:MSFlagsDefault]);

  // Will be validated in shouldFilterLog callback instead.
  OCMReject([analyticsMock validateEventName:OCMOCK_ANY forLogType:OCMOCK_ANY]);
  OCMReject([analyticsMock validateProperties:OCMOCK_ANY forLogName:OCMOCK_ANY andType:OCMOCK_ANY]);
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
  XCTAssertTrue([[MSAnalytics sharedInstance] initializationPriority] == MSInitializationPriorityDefault);
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
  [[MSAnalytics sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

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
  [[MSAnalytics sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

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
  [[MSAnalytics sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

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
  UIPageViewController *containerController = [[UIPageViewController alloc] init];
  [containerController viewWillAppear:NO];
#endif

  // Then
  OCMVerifyAll(analyticsMock);
}

- (void)testStartWithTransmissionTargetAndAppSecretUsesTransmissionTarget {

  // If
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id<MSChannelUnitProtocol> channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  __block MSEventLog *log;
  __block int invocations = 0;
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]] flags:MSFlagsDefault])
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
  OCMVerify([channelUnitMock enqueueItem:log flags:MSFlagsDefault]);
  XCTAssertTrue([[log transmissionTargetTokens] containsObject:kMSTestTransmissionToken]);
  XCTAssertEqual([[log transmissionTargetTokens] count], (unsigned long)1);
  XCTAssertEqual(invocations, 1);
}

- (void)testStartWithTransmissionTargetWithoutAppSecretUsesTransmissionTarget {

  // If
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  id<MSChannelUnitProtocol> channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  __block MSEventLog *log;
  __block int invocations = 0;
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]] flags:MSFlagsDefault])
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
  OCMVerify([channelUnitMock enqueueItem:log flags:MSFlagsDefault]);
  XCTAssertTrue([[log transmissionTargetTokens] containsObject:kMSTestTransmissionToken]);
  XCTAssertEqual([[log transmissionTargetTokens] count], (unsigned long)1);
  XCTAssertEqual(invocations, 1);
}

- (void)testGetTransmissionTargetCreatesTransmissionTargetOnce {

  // When
  MSAnalyticsTransmissionTarget *transmissionTarget1 = [MSAnalytics transmissionTargetForToken:kMSTestTransmissionToken];
  MSAnalyticsTransmissionTarget *transmissionTarget2 = [MSAnalytics transmissionTargetForToken:kMSTestTransmissionToken];

  // Then
  XCTAssertNotNil(transmissionTarget1);
  XCTAssertEqual(transmissionTarget1, transmissionTarget2);
}

- (void)testGetTransmissionTargetNeverReturnsDefault {

  // If
  [[MSAnalytics sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:nil
                              transmissionTargetToken:kMSTestTransmissionToken
                                      fromApplication:NO];

  // When
  MSAnalyticsTransmissionTarget *transmissionTarget = [MSAnalytics transmissionTargetForToken:kMSTestTransmissionToken];

  // Then
  XCTAssertNotNil([MSAnalytics sharedInstance].defaultTransmissionTarget);
  XCTAssertNotNil(transmissionTarget);
  XCTAssertNotEqual([MSAnalytics sharedInstance].defaultTransmissionTarget, transmissionTarget);
}

- (void)testEnableStatePropagateToTransmissionTargets {

  // If
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:NO];
  MSServiceAbstract *analytics = [MSAnalytics sharedInstance];
  [analytics setEnabled:NO];

  // When

  // Analytics is disabled, targets must match Analytics enabled state.
  MSAnalyticsTransmissionTarget *transmissionTarget = [MSAnalytics transmissionTargetForToken:kMSTestTransmissionToken];
  MSAnalyticsTransmissionTarget *transmissionTarget2 = [MSAnalytics transmissionTargetForToken:kMSTestTransmissionToken2];

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
  [MSAppCenter startFromLibraryWithServices:@ [[MSAnalytics class]]];

  // Then
  XCTAssertFalse([MSAnalytics sharedInstance].sessionTracker.started);

  // When
  [MSAppCenter start:MS_UUID_STRING withServices:@ [[MSAnalytics class]]];

  // Then
  XCTAssertTrue([MSAnalytics sharedInstance].sessionTracker.started);
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
  [[MSAnalytics sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:NO];

  // Then
  XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for block in applyEnabledState to be dispatched"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }

                                 // Then
                                 XCTAssertTrue([service isEnabled]);
                                 OCMReject([analyticsMock trackPage:testPageName withProperties:nil]);
                               }];
}

#pragma mark - Property validation tests

- (void)testRemoveInvalidPropertiesWithEmptyValue {

  // If
  NSDictionary *emptyValueProperties = @{@"aValidKey" : @""};

  // When
  NSDictionary *result = [[MSAnalytics sharedInstance] removeInvalidProperties:emptyValueProperties];

  // Then
  XCTAssertTrue(result.count == 1);
  XCTAssertEqualObjects(result, emptyValueProperties);
}

- (void)testRemoveInvalidPropertiesWithEmptyKey {

  // If
  NSDictionary *emptyKeyProperties = @{@"" : @"aValidValue"};

  // When
  NSDictionary *result = [[MSAnalytics sharedInstance] removeInvalidProperties:emptyKeyProperties];

  // Then
  XCTAssertTrue(result.count == 1);
}

- (void)testremoveInvalidPropertiesWithNonStringKey {

  // If
  NSDictionary *numberAsKeyProperties = @{@(42) : @"aValidValue"};

  // When
  NSDictionary *result = [[MSAnalytics sharedInstance] removeInvalidProperties:numberAsKeyProperties];

  // Then
  XCTAssertTrue(result.count == 0);
}

- (void)testValidateLogDataWithNonStringValue {

  // If
  NSDictionary *numberAsValueProperties = @{@"aValidKey" : @(42)};

  // When
  NSDictionary *result = [[MSAnalytics sharedInstance] removeInvalidProperties:numberAsValueProperties];

  // Then
  XCTAssertTrue(result.count == 0);
}

- (void)testValidateLogDataWithCorrectNestedProperties {

  // If
  NSDictionary *correctlyNestedProperties = @{@"aValidKey1" : @"aValidValue1", @"aValidKey2.aValidKey2" : @"aValidValue3"};

  // When
  NSDictionary *result = [[MSAnalytics sharedInstance] removeInvalidProperties:correctlyNestedProperties];

  // Then
  XCTAssertTrue(result.count == 2);
  XCTAssertEqualObjects(result, correctlyNestedProperties);
}

- (void)testValidateLogDataWithIncorrectNestedProperties {

  // If
  NSDictionary *incorrectNestedProperties = @{
    @"aValidKey1" : @"aValidValue1",
    @"aValidKey2" : @1,
  };

  // When
  NSDictionary *result = [[MSAnalytics sharedInstance] removeInvalidProperties:incorrectNestedProperties];

  // Then
  XCTAssertTrue(result.count == 1);
  XCTAssertNil(result[@"aValidKey2"]);
  XCTAssertNotNil(result[@"aValidKey1"]);
  XCTAssertEqualObjects(result[@"aValidKey1"], @"aValidValue1");
  XCTAssertNotEqualObjects(result, incorrectNestedProperties);
}

- (void)testDictionaryContainsInvalidPropertiesKey {

  // If
  NSDictionary *incorrectNestedProperties = @{@1 : @"aValidValue1", @"aValidKey2" : @"aValidValue2"};

  // When
  NSDictionary *result = [[MSAnalytics sharedInstance] removeInvalidProperties:incorrectNestedProperties];

  // Then
  XCTAssertTrue(result.count == 1);
  XCTAssertNotNil(result[@"aValidKey2"]);
}

- (void)testDictionaryContainsValidNestedProperties {
  NSDictionary *properties = @{@"aValidKey2" : @"aValidValue1", @"aValidKey1.avalidKey2" : @"aValidValue1"};
  // When
  NSDictionary *result = [[MSAnalytics sharedInstance] removeInvalidProperties:properties];

  // Then
  XCTAssertEqualObjects(result, properties);
}

- (void)testPropertyNameIsTruncatedInACopyWhenValidatingForAppCenter {

  // If
  MSEventProperties *properties = [MSEventProperties new];
  NSString *longKey = [@"" stringByPaddingToLength:kMSMaxPropertyKeyLength + 2 withString:@"hi" startingAtIndex:0];
  NSString *truncatedKey = [longKey substringToIndex:kMSMaxPropertyKeyLength - 1];
  [properties setString:@"test" forKey:longKey];
  MSStringTypedProperty *originalProperty = (MSStringTypedProperty *)properties.properties[longKey];

  // When
  MSEventProperties *validProperties = [[MSAnalytics sharedInstance] validateAppCenterEventProperties:properties];

  // Then
  MSStringTypedProperty *validProperty = (MSStringTypedProperty *)validProperties.properties[truncatedKey];
  XCTAssertNotNil(validProperty);
  XCTAssertEqualObjects(validProperty.name, truncatedKey);
  XCTAssertNotEqual(originalProperty, validProperty);
  XCTAssertEqualObjects(originalProperty.name, longKey);
}

- (void)testPropertyValueIsTruncatedInACopyWhenValidatingForAppCenter {

  // If
  MSEventProperties *properties = [MSEventProperties new];
  NSString *key = @"key";
  NSString *longValue = [@"" stringByPaddingToLength:kMSMaxPropertyValueLength + 2 withString:@"hi" startingAtIndex:0];
  NSString *truncatedValue = [longValue substringToIndex:kMSMaxPropertyValueLength - 1];
  [properties setString:longValue forKey:key];
  MSStringTypedProperty *originalProperty = (MSStringTypedProperty *)properties.properties[key];

  // When
  MSEventProperties *validProperties = [[MSAnalytics sharedInstance] validateAppCenterEventProperties:properties];

  // Then
  MSStringTypedProperty *validProperty = (MSStringTypedProperty *)validProperties.properties[key];
  XCTAssertEqualObjects(validProperty.value, truncatedValue);
  XCTAssertNotEqual(originalProperty, validProperty);
  XCTAssertEqualObjects(originalProperty.value, longValue);
}

- (void)testAppCenterCopyHas20PropertiesWhenSelfHasMoreThan20 {

  // If
  MSEventProperties *properties = [MSEventProperties new];

  // When
  for (int i = 0; i < kMSMaxPropertiesPerLog + 5; i++) {
    [properties setBool:YES forKey:[@(i) stringValue]];
  }
  MSEventProperties *validProperties = [[MSAnalytics sharedInstance] validateAppCenterEventProperties:properties];

  // Then
  XCTAssertEqual([validProperties.properties count], kMSMaxPropertiesPerLog);
}

- (void)testPause {

  // If
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock sharedInstance]).andReturn(appCenterMock);
  OCMStub([appCenterMock sdkConfigured]).andReturn(YES);
  id<MSChannelUnitProtocol> channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  [MSAnalytics pause];

  // Then
  OCMVerify([[MSAnalytics sharedInstance].channelUnit pauseWithIdentifyingObject:[MSAnalytics sharedInstance]]);
  [appCenterMock stopMocking];
}

- (void)testResume {

  // If
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock sharedInstance]).andReturn(appCenterMock);
  OCMStub([appCenterMock sdkConfigured]).andReturn(YES);
  id<MSChannelUnitProtocol> channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

  // When
  [MSAnalytics resume];

  // Then
  OCMVerify([[MSAnalytics sharedInstance].channelUnit resumeWithIdentifyingObject:[MSAnalytics sharedInstance]]);
  [appCenterMock stopMocking];
}

- (void)testEnablingAnalyticsResumesIt {

  // If
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock sharedInstance]).andReturn(appCenterMock);
  OCMStub([appCenterMock sdkConfigured]).andReturn(YES);
  OCMStub(ClassMethod([appCenterMock isEnabled])).andReturn(YES);
  id<MSChannelGroupProtocol> channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(OCMProtocolMock(@protocol(MSChannelUnitProtocol)));
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];
  [MSAnalytics setEnabled:NO];

  // Reset ChannelUnitMock since it's already called at startup and we want to
  // verify at enabling time.
  [MSAnalytics sharedInstance].channelUnit = OCMProtocolMock(@protocol(MSChannelUnitProtocol));

  // When
  [MSAnalytics setEnabled:YES];

  // Then
  OCMVerify([[MSAnalytics sharedInstance].channelUnit resumeWithIdentifyingObject:[MSAnalytics sharedInstance]]);
  [appCenterMock stopMocking];
}

- (void)testPauseTransmissionTargetInOneCollectorChannelUnitWhenPausedWithTargetKey {

  // If
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock sharedInstance]).andReturn(appCenterMock);
  OCMStub([appCenterMock sdkConfigured]).andReturn(YES);
  OCMStub(ClassMethod([appCenterMock isEnabled])).andReturn(YES);
  id<MSChannelGroupProtocol> channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  id<MSChannelUnitProtocol> oneCollectorChannelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelGroupMock channelUnitForGroupId:@"Analytics/one"]).andReturn(oneCollectorChannelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock appSecret:nil transmissionTargetToken:nil fromApplication:YES];
  // When
  [MSAnalytics pauseTransmissionTargetForToken:kMSTestTransmissionToken];

  // Then
  OCMVerify([oneCollectorChannelUnitMock pauseSendingLogsWithToken:kMSTestTransmissionToken]);
  [appCenterMock stopMocking];
}

- (void)testResumeTransmissionTargetInOneCollectorChannelUnitWhenResumedWithTargetKey {

  // If
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock sharedInstance]).andReturn(appCenterMock);
  OCMStub([appCenterMock sdkConfigured]).andReturn(YES);
  OCMStub(ClassMethod([appCenterMock isEnabled])).andReturn(YES);
  id<MSChannelGroupProtocol> channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  id<MSChannelUnitProtocol> oneCollectorChannelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelGroupMock channelUnitForGroupId:@"Analytics/one"]).andReturn(oneCollectorChannelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock appSecret:nil transmissionTargetToken:nil fromApplication:YES];
  // When
  [MSAnalytics resumeTransmissionTargetForToken:kMSTestTransmissionToken];

  // Then
  OCMVerify([oneCollectorChannelUnitMock resumeSendingLogsWithToken:kMSTestTransmissionToken]);
  [appCenterMock stopMocking];
}

@end
