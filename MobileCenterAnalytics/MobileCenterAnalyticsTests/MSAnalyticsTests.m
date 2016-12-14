#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "MSServiceAbstract.h"
#import "MSService.h"

#import "MSAnalytics.h"
#import "MSAnalyticsInternal.h"
#import "MSAnalyticsDelegate.h"
#import "MSMockAnalyticsDelegate.h"
#import "MSLogManager.h"
#import "MSEventLog.h"

@class MSMockAnalyticsDelegate;

@interface MSAnalyticsTests : XCTestCase<MSAnalyticsDelegate>

@property BOOL willSendEventLogWasCalled;
@property BOOL didSucceedSendingEventLogWasCalled;
@property BOOL didFailSendingEventLogWasCalled;

@end

@interface MSAnalytics ()

@property (nonatomic) id<MSAnalyticsDelegate> delegate;

- (void)channel:(id)channel willSendLog:(id<MSLog>)log;
- (void)channel:(id<MSChannel>)channel didSucceedSendingLog:(id<MSLog>)log;
- (void)channel:(id<MSChannel>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error;

@end

@interface MSServiceAbstract ()

- (BOOL) isEnabled;
- (void) setEnabled:(BOOL)enabled;

@end



@implementation MSAnalyticsTests

#pragma mark - Tests


- (void)testValidatePropertyType {

  // If
  NSDictionary *validProperties = @{@"Key1": @"Value1", @"Key2": @"Value2", @"Key3": @"Value3"};
  NSDictionary *invalidKeyInProperties = @{@"Key1": @"Value1", @"Key2": @(2), @"Key3": @"Value3"};
  NSDictionary *invalidValueInProperties = @{@"Key1": @"Value1", @(2): @"Value2", @"Key3": @"Value3"};

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
  [[MSAnalytics sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager))];

  MSServiceAbstract *service = (MSServiceAbstract*)[MSAnalytics sharedInstance];

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

- (void)analytics:(MSAnalytics *)analytics willSendEventLog:(MSEventLog *)eventLog
{
  self.willSendEventLogWasCalled = true;
}

- (void)analytics:(MSAnalytics *)analytics didSucceedSendingEventLog:(MSEventLog *)eventLog
{
  self.didSucceedSendingEventLogWasCalled = true;
}

- (void)analytics:(MSAnalytics *)analytics didFailSendingEventLog:(MSEventLog *)eventLog withError:(NSError *)error
{
  self.didFailSendingEventLogWasCalled = true;
}


@end
