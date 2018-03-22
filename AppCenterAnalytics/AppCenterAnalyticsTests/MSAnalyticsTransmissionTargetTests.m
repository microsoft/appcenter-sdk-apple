@import XCTest;

#import "MSAnalyticsInternal.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSTestFrameworks.h"

static NSString *const kMSTestTransmissionToken = @"TestTransmissionToken";

@interface MSAnalyticsTransmissionTargetTests : XCTestCase
@end

@implementation MSAnalyticsTransmissionTargetTests

#pragma mark - Tests

- (void)testInitialization {

  // When
  MSAnalyticsTransmissionTarget *transmissionTarget = [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken];

  // Then
  XCTAssertNotNil(transmissionTarget);
  XCTAssertEqual(kMSTestTransmissionToken, [transmissionTarget transmissionTargetToken]);
}

- (void)testTrackEvent {

  // If
  OCMClassMock([MSAnalytics class]);
  MSAnalyticsTransmissionTarget *transmissionTarget = [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken];
  NSString *eventName = @"event";

  // When
  [transmissionTarget trackEvent:eventName];

  // Then
  OCMVerify(ClassMethod([MSAnalytics trackEvent:eventName forTransmissionTarget:transmissionTarget]));
}

- (void)testTrackEventWithProperties {

  // If
  OCMClassMock([MSAnalytics class]);
  MSAnalyticsTransmissionTarget *transmissionTarget = [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken];
  NSString *eventName = @"event";
  NSDictionary *properties = [NSDictionary new];

  // When
  [transmissionTarget trackEvent:eventName withProperties:properties];

  // Then
  OCMVerify(ClassMethod([MSAnalytics trackEvent:eventName withProperties:properties forTransmissionTarget:transmissionTarget]));
}

@end

