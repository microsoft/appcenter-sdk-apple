#import "MSAnalyticsInternal.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSTestFrameworks.h"

static NSString *const kMSTestTransmissionToken = @"TestTransmissionToken";
static NSString *const kMSTestTransmissionToken2 = @"TestTransmissionToken2";

@interface MSAnalyticsTransmissionTargetTests : XCTestCase
@end

@implementation MSAnalyticsTransmissionTargetTests

#pragma mark - Tests

- (void)testInitialization {

  // When
  MSAnalyticsTransmissionTarget *transmissionTarget =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken];

  // Then
  XCTAssertNotNil(transmissionTarget);
  XCTAssertEqual(kMSTestTransmissionToken, transmissionTarget.transmissionTargetToken);
}

- (void)testTrackEvent {

  // If
  OCMClassMock([MSAnalytics class]);
  MSAnalyticsTransmissionTarget *transmissionTarget =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken];
  NSString *eventName = @"event";

  // When
  [transmissionTarget trackEvent:eventName];

  // Then
  OCMVerify(ClassMethod([MSAnalytics trackEvent:eventName forTransmissionTarget:transmissionTarget]));
}

- (void)testTrackEventWithProperties {

  // If
  OCMClassMock([MSAnalytics class]);
  MSAnalyticsTransmissionTarget *transmissionTarget =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken];
  NSString *eventName = @"event";
  NSDictionary *properties = [NSDictionary new];

  // When
  [transmissionTarget trackEvent:eventName withProperties:properties];

  // Then
  OCMVerify(ClassMethod(
      [MSAnalytics trackEvent:eventName withProperties:properties forTransmissionTarget:transmissionTarget]));
}

- (void)testTransmissionTargetForToken {

  // If
  OCMClassMock([MSAnalytics class]);
  NSDictionary *properties = [NSDictionary new];
  NSString *event1 = @"event1";
  NSString *event2 = @"event2";
  NSString *event3 = @"event3";

  MSAnalyticsTransmissionTarget *parentTransmissionTarget =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken];
  MSAnalyticsTransmissionTarget *childTransmissionTarget;

  // When
  childTransmissionTarget = [parentTransmissionTarget transmissionTargetForToken:kMSTestTransmissionToken2];
  [childTransmissionTarget trackEvent:event1 withProperties:properties];

  // Then
  XCTAssertEqualObjects(kMSTestTransmissionToken2, childTransmissionTarget.transmissionTargetToken);
  XCTAssertEqualObjects(childTransmissionTarget,
                        parentTransmissionTarget.childTransmissionTargets[kMSTestTransmissionToken2]);

  // When
  MSAnalyticsTransmissionTarget *childTransmissionTarget2 =
      [parentTransmissionTarget transmissionTargetForToken:kMSTestTransmissionToken2];
  [childTransmissionTarget2 trackEvent:event2 withProperties:properties];

  // Then
  XCTAssertEqualObjects(childTransmissionTarget, childTransmissionTarget2);
  XCTAssertEqualObjects(childTransmissionTarget2,
                        parentTransmissionTarget.childTransmissionTargets[kMSTestTransmissionToken2]);

  // When
  MSAnalyticsTransmissionTarget *childTransmissionTarget3 =
      [parentTransmissionTarget transmissionTargetForToken:kMSTestTransmissionToken];
  [childTransmissionTarget3 trackEvent:event3 withProperties:properties];

  // Then
  XCTAssertNotEqualObjects(parentTransmissionTarget, childTransmissionTarget3);
  XCTAssertEqualObjects(childTransmissionTarget3,
                        parentTransmissionTarget.childTransmissionTargets[kMSTestTransmissionToken]);
  OCMVerify(ClassMethod(
      [MSAnalytics trackEvent:event1 withProperties:properties forTransmissionTarget:childTransmissionTarget]));
  OCMVerify(ClassMethod(
      [MSAnalytics trackEvent:event2 withProperties:properties forTransmissionTarget:childTransmissionTarget2]));
  OCMVerify(ClassMethod(
      [MSAnalytics trackEvent:event3 withProperties:properties forTransmissionTarget:childTransmissionTarget3]));
}

@end
