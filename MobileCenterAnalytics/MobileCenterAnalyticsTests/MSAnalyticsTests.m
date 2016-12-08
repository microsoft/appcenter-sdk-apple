#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "MSAnalytics.h"
#import "MSAnalyticsInternal.h"
#import "MSAnalyticsDelegate.h"
#import "MSMockAnalyticsDelegate.h"

@class MSMockAnalyticsDelegate;

@interface MSAnalyticsTests : XCTestCase
@end

@interface MSAnalytics ()
@property (nonatomic) id<MSAnalyticsDelegate> delegate;
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

@end
