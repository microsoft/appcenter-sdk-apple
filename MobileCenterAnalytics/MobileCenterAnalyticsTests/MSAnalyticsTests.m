#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#import "MSMobileCenter.h"
#import "MSServiceAbstract.h"
#import "MSServiceInternal.h"

#import "MSAnalytics.h"
#import "MSAnalyticsPrivate.h"
#import "MSAnalyticsInternal.h"
#import "MSMockAnalyticsDelegate.h"
#import "MSEventLog.h"

static NSString *const kMSTypeEvent = @"event";
static NSString *const kMSTypePage = @"page";
static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSAnalyticsServiceName = @"Analytics";

@class MSMockAnalyticsDelegate;

@interface MSAnalyticsTests : XCTestCase <MSAnalyticsDelegate>

@property BOOL willSendEventLogWasCalled;
@property BOOL didSucceedSendingEventLogWasCalled;
@property BOOL didFailSendingEventLogWasCalled;

@end

@interface MSAnalytics ()

- (void)channel:(id)channel willSendLog:(id<MSLog>)log;

- (void)channel:(id<MSChannel>)channel didSucceedSendingLog:(id<MSLog>)log;

- (void)channel:(id<MSChannel>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error;

@end

@interface MSServiceAbstract ()

- (BOOL)isEnabled;

- (void)setEnabled:(BOOL)enabled;

@end

@implementation MSAnalyticsTests

- (void)tearDown {
  [super tearDown];
  [MSAnalytics resetSharedInstance];
}

#pragma mark - Tests

- (void)testValidatePropertyType {

  // If
  NSDictionary *validProperties = @{ @"Key1" : @"Value1", @"Key2" : @"Value2", @"Key3" : @"Value3" };
  NSDictionary *invalidKeyInProperties = @{ @"Key1" : @"Value1", @"Key2" : @(2), @"Key3" : @"Value3" };
  NSDictionary *invalidValueInProperties = @{ @"Key1" : @"Value1", @(2) : @"Value2", @"Key3" : @"Value3" };

  // When
  BOOL valid = [[MSAnalytics sharedInstance] validateProperties:validProperties];
  BOOL invalidKey = [[MSAnalytics sharedInstance] validateProperties:invalidKeyInProperties];
  BOOL invalidValue = [[MSAnalytics sharedInstance] validateProperties:invalidValueInProperties];

  // Then
  XCTAssertTrue(valid);
  XCTAssertFalse(invalidKey);
  XCTAssertFalse(invalidValue);
}

- (void)testApplyEnabledStateWorks {
  [[MSAnalytics sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager))
                                          appSecret:kMSTestAppSecret];

  MSServiceAbstract *service = (MSServiceAbstract *)[MSAnalytics sharedInstance];

  [service setEnabled:YES];
  XCTAssertTrue([service isEnabled]);

  [service setEnabled:NO];
  XCTAssertFalse([service isEnabled]);

  [service setEnabled:YES];
  XCTAssertTrue([service isEnabled]);
}

- (void)testSettingDelegateWorks {
  id<MSAnalyticsDelegate> delegateMock = OCMProtocolMock(@protocol(MSAnalyticsDelegate));
  [MSAnalytics setDelegate:delegateMock];
  XCTAssertNotNil([MSAnalytics sharedInstance].delegate);
  XCTAssertEqual([MSAnalytics sharedInstance].delegate, delegateMock);
}

- (void)testAnalyticsDelegateWithoutImplementations {

  // When
  MSMockAnalyticsDelegate *delegateMock = OCMPartialMock([MSMockAnalyticsDelegate new]);
  [MSAnalytics setDelegate:delegateMock];

  id<MSAnalyticsDelegate> delegate = [[MSAnalytics sharedInstance] delegate];

  // Then
  XCTAssertFalse([delegate respondsToSelector:@selector(analytics:willSendEventLog:)]);
  XCTAssertFalse([delegate respondsToSelector:@selector(analytics:didSucceedSendingEventLog:)]);
  XCTAssertFalse([delegate respondsToSelector:@selector(analytics:didFailSendingEventLog:withError:)]);
  XCTAssertFalse([delegate respondsToSelector:@selector(analytics:willSendPageLog:)]);
  XCTAssertFalse([delegate respondsToSelector:@selector(analytics:didSucceedSendingPageLog:)]);
  XCTAssertFalse([delegate respondsToSelector:@selector(analytics:didFailSendingPageLog:withError:)]);
}

- (void)testAnalyticsDelegateMethodsAreCalled {

  self.willSendEventLogWasCalled = false;
  self.didSucceedSendingEventLogWasCalled = false;
  self.didFailSendingEventLogWasCalled = false;
  [[MSAnalytics sharedInstance] setDelegate:self];
  MSEventLog *eventLog = [MSEventLog new];
  [[MSAnalytics sharedInstance] channel:nil willSendLog:eventLog];
  [[MSAnalytics sharedInstance] channel:nil didSucceedSendingLog:eventLog];
  [[MSAnalytics sharedInstance] channel:nil didFailSendingLog:eventLog withError:nil];

  XCTAssertTrue(self.willSendEventLogWasCalled);
  XCTAssertTrue(self.didSucceedSendingEventLogWasCalled);
  XCTAssertTrue(self.didFailSendingEventLogWasCalled);
}

- (void)testTrackEventWithoutProperties {

  // If
  __block NSString *name;
  __block NSString *type;
  NSString *expectedName = @"gotACoffee";
  id<MSLogManager> logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  OCMStub([logManagerMock processLog:[OCMArg isKindOfClass:[MSLogWithProperties class]]
                        withPriority:([MSAnalytics sharedInstance].priority)])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        type = log.type;
        name = log.name;
      });
  [MSMobileCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithLogManager:logManagerMock appSecret:kMSTestAppSecret];

  // When
  [MSAnalytics trackEvent:expectedName];

  // Then
  assertThat(type, is(kMSTypeEvent));
  assertThat(name, is(expectedName));
}

- (void)testTrackEventWithProperties {

  // If
  __block NSString *type;
  __block NSString *name;
  __block NSDictionary<NSString *, NSString *> *properties;
  NSString *expectedName = @"gotACoffee";
  NSDictionary *expectedProperties = @{ @"milk" : @"yes", @"cookie" : @"of course" };
  id<MSLogManager> logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  OCMStub([logManagerMock processLog:[OCMArg isKindOfClass:[MSLogWithProperties class]]
                        withPriority:([MSAnalytics sharedInstance].priority)])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        type = log.type;
        name = log.name;
        properties = log.properties;
      });
  [MSMobileCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithLogManager:logManagerMock appSecret:kMSTestAppSecret];

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
  id<MSLogManager> logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  OCMStub([logManagerMock processLog:[OCMArg isKindOfClass:[MSLogWithProperties class]]
                        withPriority:([MSAnalytics sharedInstance].priority)])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        type = log.type;
        name = log.name;
      });
  [MSMobileCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithLogManager:logManagerMock appSecret:kMSTestAppSecret];

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
  id<MSLogManager> logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  OCMStub([logManagerMock processLog:[OCMArg isKindOfClass:[MSLogWithProperties class]]
                        withPriority:([MSAnalytics sharedInstance].priority)])
      .andDo(^(NSInvocation *invocation) {
        MSEventLog *log;
        [invocation getArgument:&log atIndex:2];
        type = log.type;
        name = log.name;
        properties = log.properties;
      });
  [MSMobileCenter configureWithAppSecret:kMSTestAppSecret];
  [[MSAnalytics sharedInstance] startWithLogManager:logManagerMock appSecret:kMSTestAppSecret];

  // When
  [MSAnalytics trackPage:expectedName withProperties:expectedProperties];

  // Then
  assertThat(type, is(kMSTypePage));
  assertThat(name, is(expectedName));
  assertThat(properties, is(expectedProperties));
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

- (void)analytics:(MSAnalytics *)analytics willSendEventLog:(MSEventLog *)eventLog {
  self.willSendEventLogWasCalled = true;
}

- (void)analytics:(MSAnalytics *)analytics didSucceedSendingEventLog:(MSEventLog *)eventLog {
  self.didSucceedSendingEventLogWasCalled = true;
}

- (void)analytics:(MSAnalytics *)analytics didFailSendingEventLog:(MSEventLog *)eventLog withError:(NSError *)error {
  self.didFailSendingEventLogWasCalled = true;
}

- (void)testInitializationPriorityCorrect {
  XCTAssertTrue([[MSAnalytics sharedInstance] initializationPriority] == MSInitializationPriorityDefault);
}

- (void)testServiceNameIsCorrect {
  XCTAssertEqual([MSAnalytics serviceName], kMSAnalyticsServiceName);
}

@end
