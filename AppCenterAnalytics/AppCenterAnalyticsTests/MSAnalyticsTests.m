#import "MSAnalytics.h"
#import "MSAnalyticsInternal.h"
#import "MSAnalyticsPrivate.h"
#import "MSAnalyticsCategory.h"
#import "MSAnalytics+Validation.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSChannelGroupDefault.h"
#import "MSChannelUnitDefault.h"
#import "MSConstants+Internal.h"
#import "MSEventLog.h"
#import "MSPageLog.h"
#import "MSMockAnalyticsDelegate.h"
#import "MSServiceAbstract.h"
#import "MSServiceInternal.h"
#import "MSTestFrameworks.h"

static NSString *const kMSTypeEvent = @"event";
static NSString *const kMSTypePage = @"page";
static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSTestTransmissionToken = @"TestTransmissionToken";
static NSString *const kMSAnalyticsServiceName = @"Analytics";

@class MSMockAnalyticsDelegate;

@interface MSAnalyticsTests : XCTestCase <MSAnalyticsDelegate>

@end

@interface MSServiceAbstract ()

- (BOOL)isEnabled;

- (void)setEnabled:(BOOL)enabled;

@end

@interface MSAnalytics ()

- (void)shouldFilterLog:(id<MSLog>)log;

@end

/*
 * FIXME
 * Log manager mock is holding sessionTracker instance even after dealloc and this causes session tracker test failures.
 * There is a PR in OCMock that seems a related issue. https://github.com/erikdoe/ocmock/pull/348
 * Stopping session tracker after applyEnabledState calls for hack to avoid failures.
 */
@implementation MSAnalyticsTests

- (void)tearDown {
  [super tearDown];

  // Make sure sessionTracker removes all observers.
  [MSAnalytics sharedInstance].sessionTracker = nil;
  [MSAnalytics resetSharedInstance];
}

#pragma mark - Tests

- (void)testValidateACEventName {
  const int maxEventNameLength = 256;

  // If
  NSString *validEventName = @"validEventName";
  NSString *shortEventName = @"e";
  NSString *eventName256 =
      [@"" stringByPaddingToLength:maxEventNameLength withString:@"eventName256" startingAtIndex:0];
  NSString *nullableEventName = nil;
  NSString *emptyEventName = @"";
  NSString *tooLongEventName =
      [@"" stringByPaddingToLength:(maxEventNameLength + 1) withString:@"tooLongEventName" startingAtIndex:0];
  // When
  NSString *valid = [[MSAnalytics sharedInstance] validateACEventName:validEventName forLogType:kMSTypeEvent];
  NSString *validShortEventName =
      [[MSAnalytics sharedInstance] validateACEventName:shortEventName forLogType:kMSTypeEvent];
  NSString *validEventName256 = [[MSAnalytics sharedInstance] validateACEventName:eventName256 forLogType:kMSTypeEvent];
  NSString *validNullableEventName =
      [[MSAnalytics sharedInstance] validateACEventName:nullableEventName forLogType:kMSTypeEvent];
  NSString *validEmptyEventName =
      [[MSAnalytics sharedInstance] validateACEventName:emptyEventName forLogType:kMSTypeEvent];
  NSString *validTooLongEventName =
      [[MSAnalytics sharedInstance] validateACEventName:tooLongEventName forLogType:kMSTypeEvent];

  // Then
  XCTAssertNotNil(valid);
  XCTAssertNotNil(validShortEventName);
  XCTAssertNotNil(validEventName256);
  XCTAssertNil(validNullableEventName);
  XCTAssertNil(validEmptyEventName);
  XCTAssertNotNil(validTooLongEventName);
  XCTAssertEqual([validTooLongEventName length], maxEventNameLength);
}

- (void)testValidateCSEventName {
  const int maxEventNameLength = 100;

  // If
  NSString *validEventName = @"valid.CS.event.name";
  NSString *shortEventName = @"e";
  NSString *eventName100 =
      [@"" stringByPaddingToLength:maxEventNameLength withString:@"csEventName100" startingAtIndex:0];
  NSString *nullableEventName = nil;
  NSString *emptyEventName = @"";
  NSString *tooLongEventName =
      [@"" stringByPaddingToLength:(maxEventNameLength + 1) withString:@"tooLongCSEventName" startingAtIndex:0];
  NSString *periodAndUnderscoreEventName = @"hello.world_mamamia";
  NSString *leadingPeriodEventName = @".hello.world";
  NSString *trailingPeriodEventName = @"hello.world.";
  NSString *consecutivePeriodEventName = @"hello..world";
  NSString *headingUnderscoreEventName = @"_hello.world";
  NSString *specialCharactersOtherThanPeriodAndUnderscore = @"hello%^&world";

  // When
  BOOL valid = [[MSAnalytics sharedInstance] validateCSEventName:validEventName];
  BOOL validShortEventName = [[MSAnalytics sharedInstance] validateCSEventName:shortEventName];
  BOOL validEventName100 = [[MSAnalytics sharedInstance] validateCSEventName:eventName100];
  BOOL invalidNullableEventName = [[MSAnalytics sharedInstance] validateCSEventName:nullableEventName];
  BOOL invalidEmptyEventName = [[MSAnalytics sharedInstance] validateCSEventName:emptyEventName];
  BOOL invalidTooLongEventName = [[MSAnalytics sharedInstance] validateCSEventName:tooLongEventName];
  BOOL validPeriodAndUnderscoreEventName =
      [[MSAnalytics sharedInstance] validateCSEventName:periodAndUnderscoreEventName];
  BOOL invalidLeadingPeriodEventName = [[MSAnalytics sharedInstance] validateCSEventName:leadingPeriodEventName];
  BOOL invalidTrailingPeriodEventName = [[MSAnalytics sharedInstance] validateCSEventName:trailingPeriodEventName];
  BOOL invalidConsecutivePeriodEventName =
      [[MSAnalytics sharedInstance] validateCSEventName:consecutivePeriodEventName];
  BOOL invalidHeadingUnderscoreEventName =
      [[MSAnalytics sharedInstance] validateCSEventName:headingUnderscoreEventName];
  BOOL invalidCharactersOtherThanPeriodAndUnderscoreEventName =
      [[MSAnalytics sharedInstance] validateCSEventName:specialCharactersOtherThanPeriodAndUnderscore];

  // Then
  XCTAssertTrue(valid);
  XCTAssertTrue(validShortEventName);
  XCTAssertTrue(validEventName100);
  XCTAssertFalse(invalidNullableEventName);
  XCTAssertFalse(invalidEmptyEventName);
  XCTAssertFalse(invalidTooLongEventName);
  XCTAssertTrue(validPeriodAndUnderscoreEventName);
  XCTAssertFalse(invalidLeadingPeriodEventName);
  XCTAssertFalse(invalidTrailingPeriodEventName);
  XCTAssertFalse(invalidConsecutivePeriodEventName);
  XCTAssertFalse(invalidHeadingUnderscoreEventName);
  XCTAssertFalse(invalidCharactersOtherThanPeriodAndUnderscoreEventName);
}

- (void)testValidateCSDataPropertiesFieldNames {

  // If
  NSString *shortPropertyName = @"i";
  NSString *propertyName100 =
      [@"" stringByPaddingToLength:100 withString:@"cs.data.property.Name100" startingAtIndex:0];
  NSString *emptyPropertyName = @"";
  NSString *tooLongPropertyName =
      [@"" stringByPaddingToLength:101 withString:@"cs.data.property.Name101" startingAtIndex:0];
  NSString *leadingPeriod = @".hello.world";
  NSString *leadingUnderscore = @"_hello.world";
  NSString *dotInPropertyName = @"hello.world";
  NSString *underscoreInPropertyName = @"hello_world";
  NSString *doNotAllowSpaceInPropertyName = @"hello world";
  NSString *notAllowOtherSpecialCharsInPropertyName = @"$#%^&*";
  NSString *startWithNumberPropertyName = @"9.hello.world";
  NSMutableDictionary *properties = [NSMutableDictionary new];
  MSCSData *data = [MSCSData new];

  // When
  properties[shortPropertyName] = @"shortPropertyNameValue";
  data.properties = properties;
  BOOL validShortPropertyName = [[MSAnalytics sharedInstance] validateCSDataPropertiesFieldNames:data];

  // Then
  XCTAssertTrue(validShortPropertyName);
  [properties removeAllObjects];

  // When
  properties[propertyName100] = @"propertyName100Value";
  data.properties = properties;
  BOOL validPropertyName100 = [[MSAnalytics sharedInstance] validateCSDataPropertiesFieldNames:data];

  // Then
  XCTAssertTrue(validPropertyName100);
  [properties removeAllObjects];

  // When
  properties[emptyPropertyName] = @"";
  data.properties = properties;
  BOOL invalidEmptyPropertyName = [[MSAnalytics sharedInstance] validateCSDataPropertiesFieldNames:data];

  // Then
  XCTAssertFalse(invalidEmptyPropertyName);
  [properties removeAllObjects];

  // When
  properties[tooLongPropertyName] = @"tooLongPropertyNameValue";
  data.properties = properties;
  BOOL invalidTooLongPropertyName = [[MSAnalytics sharedInstance] validateCSDataPropertiesFieldNames:data];

  // Then
  XCTAssertFalse(invalidTooLongPropertyName);
  [properties removeAllObjects];

  // When
  properties[leadingPeriod] = @".leading.period";
  data.properties = properties;
  BOOL invalidLeadingPeriodPropertyName = [[MSAnalytics sharedInstance] validateCSDataPropertiesFieldNames:data];

  // Then
  XCTAssertFalse(invalidLeadingPeriodPropertyName);
  [properties removeAllObjects];

  // When
  properties[leadingUnderscore] = @"_leading.period";
  data.properties = properties;
  BOOL invalidLeadingUnderscorePropertyName = [[MSAnalytics sharedInstance] validateCSDataPropertiesFieldNames:data];

  // Then
  XCTAssertFalse(invalidLeadingUnderscorePropertyName);
  [properties removeAllObjects];

  // When
  properties[dotInPropertyName] = @"hello.world";
  data.properties = properties;
  BOOL validDotInPropertyName = [[MSAnalytics sharedInstance] validateCSDataPropertiesFieldNames:data];

  // Then
  XCTAssertTrue(validDotInPropertyName);
  [properties removeAllObjects];

  // When
  properties[underscoreInPropertyName] = @"hello_world";
  data.properties = properties;
  BOOL validUnderscoreInPropertyName = [[MSAnalytics sharedInstance] validateCSDataPropertiesFieldNames:data];

  XCTAssertTrue(validUnderscoreInPropertyName);
  [properties removeAllObjects];

  // When
  properties[doNotAllowSpaceInPropertyName] = @"hello world";
  data.properties = properties;
  BOOL invalidDoNotAllowSpaceInPropertyName = [[MSAnalytics sharedInstance] validateCSDataPropertiesFieldNames:data];

  // Then
  XCTAssertFalse(invalidDoNotAllowSpaceInPropertyName);
  [properties removeAllObjects];

  // When
  properties[notAllowOtherSpecialCharsInPropertyName] = @"special chars other than underscore and dot";
  data.properties = properties;
  BOOL invalidNotAllowOtherSpecialCharsInPropertyName =
      [[MSAnalytics sharedInstance] validateCSDataPropertiesFieldNames:data];

  // Then
  XCTAssertFalse(invalidNotAllowOtherSpecialCharsInPropertyName);
  [properties removeAllObjects];

  // When
  properties[startWithNumberPropertyName] = @"startWithNumberValue";
  data.properties = properties;
  BOOL invalidStartWithNumberPropertyName = [[MSAnalytics sharedInstance] validateCSDataPropertiesFieldNames:data];

  // Then
  XCTAssertFalse(invalidStartWithNumberPropertyName);
}

- (void)testApplyEnabledStateWorks {
  [[MSAnalytics sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil];

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
                              transmissionTargetToken:nil];

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  XCTestExpectation *expection =
      [self expectationWithDescription:@"Wait for block in applyEnabledState to be dispatched"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expection fulfill];
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
  [MSAppCenter start:kMSTestAppSecret withServices:@[ [MSAnalytics class] ]];
  MSChannelUnitDefault *channelMock = [MSAnalytics sharedInstance].channelUnit =
      OCMPartialMock([MSAnalytics sharedInstance].channelUnit);
  OCMStub([channelMock enqueueItem:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
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
  id<MSAnalyticsDelegate> delegateMock = OCMProtocolMock(@protocol(MSAnalyticsDelegate));
  [MSAppCenter sharedInstance].sdkConfigured = NO;
  [MSAppCenter start:kMSTestAppSecret withServices:@[ [MSAnalytics class] ]];
  MSChannelUnitDefault *channelMock = [MSAnalytics sharedInstance].channelUnit =
      OCMPartialMock([MSAnalytics sharedInstance].channelUnit);
  OCMStub([channelMock enqueueItem:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
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
  OCMVerify([delegateMock analytics:[MSAnalytics sharedInstance] willSendEventLog:eventLog]);
  OCMVerify([delegateMock analytics:[MSAnalytics sharedInstance] didSucceedSendingEventLog:eventLog]);
  OCMVerify([delegateMock analytics:[MSAnalytics sharedInstance] didFailSendingEventLog:eventLog withError:nil]);
}

- (void)testAnalyticsLogsVerificationIsCalled {

  // If
  MSEventLog *eventLog = [MSEventLog new];
  eventLog.name = @"test";
  eventLog.properties = @{ @"test" : @"test" };
  MSPageLog *pageLog = [MSPageLog new];
  MSLogWithNameAndProperties *analyticsLog = [MSLogWithNameAndProperties new];
  id analyticsMock = OCMPartialMock([MSAnalytics sharedInstance]);
  OCMExpect([analyticsMock validateACLog:eventLog]).andForwardToRealObject();
  OCMExpect([analyticsMock validateACEventName:@"test" forLogType:@"event"]).andForwardToRealObject();
  OCMExpect([analyticsMock validateACProperties:OCMOCK_ANY forLogName:@"test" andType:@"event"])
      .andForwardToRealObject();
  OCMExpect([analyticsMock validateACLog:pageLog]).andForwardToRealObject();
  OCMExpect([analyticsMock validateACEventName:OCMOCK_ANY forLogType:@"page"]).andForwardToRealObject();
  OCMReject([analyticsMock validateACProperties:OCMOCK_ANY forLogName:OCMOCK_ANY andType:@"page"]);
  OCMReject([analyticsMock validateACLog:analyticsLog]);

  // When
  [[MSAnalytics sharedInstance] shouldFilterLog:eventLog];
  [[MSAnalytics sharedInstance] shouldFilterLog:pageLog];
  [[MSAnalytics sharedInstance] shouldFilterLog:analyticsLog];

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
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]]])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        type = log.type;
        name = log.name;
      });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil];

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
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
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil];

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  // When
  OCMReject([channelUnitMock enqueueItem:OCMOCK_ANY]);
  [[MSAnalytics sharedInstance] trackEvent:@"Some event" withProperties:nil forTransmissionTarget:nil];

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
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil];

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  // When
  OCMExpect([channelUnitMock enqueueItem:OCMOCK_ANY]);

  // Will be validated in shouldFilterLog callback instead.
  OCMReject([analyticsMock validateACEventName:OCMOCK_ANY forLogType:OCMOCK_ANY]);
  OCMReject([analyticsMock validateACProperties:OCMOCK_ANY forLogName:OCMOCK_ANY andType:OCMOCK_ANY]);
  [[MSAnalytics sharedInstance] trackEvent:invalidEventName withProperties:nil forTransmissionTarget:nil];

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
  NSDictionary *expectedProperties = @{ @"milk" : @"yes", @"cookie" : @"of course" };
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]]])
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
                              transmissionTargetToken:nil];

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
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
  id<MSChannelUnitProtocol> channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]]])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        type = log.type;
        name = log.name;
      });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil];

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
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
  NSDictionary *expectedProperties = @{ @"Sofa" : @"yes", @"TV" : @"of course" };
  id<MSChannelUnitProtocol> channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelGroupProtocol> channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]]])
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
                              transmissionTargetToken:nil];

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
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
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);

  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil];

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
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
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil];

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
  [[MSAnalytics sharedInstance].sessionTracker stop];

  // When
  OCMExpect([channelUnitMock enqueueItem:OCMOCK_ANY]);

  // Will be validated in shouldFilterLog callback instead.
  OCMReject([analyticsMock validateACEventName:OCMOCK_ANY forLogType:OCMOCK_ANY]);
  OCMReject([analyticsMock validateACProperties:OCMOCK_ANY forLogName:OCMOCK_ANY andType:OCMOCK_ANY]);
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
                              transmissionTargetToken:nil];

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
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
  [[MSAnalytics sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil];

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
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
  [[MSAnalytics sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil];

  // FIXME: logManager holds session tracker somehow and it causes other test failures. Stop it for hack.
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
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]]])
      .andDo(^(NSInvocation *invocation) {
        ++invocations;
        [invocation getArgument:&log atIndex:2];
      });
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:kMSTestTransmissionToken];

  // When
  [MSAnalytics trackEvent:@"eventName"];

  // Then
  OCMVerify([channelUnitMock enqueueItem:log]);
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
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSLogWithProperties class]]])
      .andDo(^(NSInvocation *invocation) {
        ++invocations;
        [invocation getArgument:&log atIndex:2];
      });
  [[MSAnalytics sharedInstance] startWithChannelGroup:channelGroupMock
                                            appSecret:nil
                              transmissionTargetToken:kMSTestTransmissionToken];

  // When
  [MSAnalytics trackEvent:@"eventName"];

  // Then
  OCMVerify([channelUnitMock enqueueItem:log]);
  XCTAssertTrue([[log transmissionTargetTokens] containsObject:kMSTestTransmissionToken]);
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

- (void)testAppSecretNotRequired {
  XCTAssertFalse([[MSAnalytics sharedInstance] isAppSecretRequired]);
}

@end
