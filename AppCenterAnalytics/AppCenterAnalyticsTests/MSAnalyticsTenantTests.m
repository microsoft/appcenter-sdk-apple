@import XCTest;

#import "MSAnalyticsInternal.h"
#import "MSAnalyticsTenantInternal.h"
#import "MSTestFrameworks.h"

static NSString *const kMSTestTenantId = @"TestTenantId";

@interface MSAnalyticsTenantTests : XCTestCase
@end

@implementation MSAnalyticsTenantTests

#pragma mark - Tests

- (void)testInitialization {

  // When
  MSAnalyticsTenant *tenant = [[MSAnalyticsTenant alloc] initWithTenantId:kMSTestTenantId];

  // Then
  XCTAssertNotNil(tenant);
  XCTAssertEqual(kMSTestTenantId, [tenant tenantId]);
}

- (void)testTrackEvent {

  // If
  OCMClassMock([MSAnalytics class]);
  MSAnalyticsTenant *tenant = [[MSAnalyticsTenant alloc] initWithTenantId:kMSTestTenantId];
  NSString *eventName = @"event";

  // When
  [tenant trackEvent:eventName];

  // Then
  OCMVerify(ClassMethod([MSAnalytics trackEvent:eventName forTenant:tenant]));
}

- (void)testTrackEventWithProperties {

  // If
  OCMClassMock([MSAnalytics class]);
  MSAnalyticsTenant *tenant = [[MSAnalyticsTenant alloc] initWithTenantId:kMSTestTenantId];
  NSString *eventName = @"event";
  NSDictionary *properties = [NSDictionary new];

  // When
  [tenant trackEvent:eventName withProperties:properties];

  // Then
  OCMVerify(ClassMethod([MSAnalytics trackEvent:eventName withProperties:properties forTenant:tenant]));
}

@end

