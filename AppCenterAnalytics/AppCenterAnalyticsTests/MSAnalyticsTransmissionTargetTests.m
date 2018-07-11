#import "MSAnalyticsInternal.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"

static NSString *const kMSTestTransmissionToken = @"TestTransmissionToken";
static NSString *const kMSTestTransmissionToken2 = @"TestTransmissionToken2";

@interface MSAnalyticsTransmissionTargetTests : XCTestCase

@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) id analyticsClassMock;

@end

@implementation MSAnalyticsTransmissionTargetTests

- (void)setUp {
  [super setUp];

  // Mock NSUserDefaults
  self.settingsMock = [MSMockUserDefaults new];

  // Analytics enabled state can prevent targets from tracking events.
  self.analyticsClassMock = OCMClassMock([MSAnalytics class]);
  OCMStub(ClassMethod([self.analyticsClassMock isEnabled])).andReturn(YES);
}

- (void)tearDown {
  [self.settingsMock stopMocking];
  [self.analyticsClassMock stopMocking];
  [super tearDown];
}

#pragma mark - Tests

- (void)testInitialization {

  // When
  MSAnalyticsTransmissionTarget *transmissionTarget =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken parentTarget:nil];

  // Then
  XCTAssertNotNil(transmissionTarget);
  XCTAssertEqual(kMSTestTransmissionToken, transmissionTarget.transmissionTargetToken);
  XCTAssertEqualObjects(transmissionTarget.eventProperties, @{});
}

- (void)testTrackEvent {

  // If
  MSAnalyticsTransmissionTarget *target =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken parentTarget:nil];
  NSString *eventName = @"event";

  // When
  [target trackEvent:eventName];

  // Then
  XCTAssertTrue(target.eventProperties.count == 0);
  OCMVerify(
      ClassMethod([self.analyticsClassMock trackEvent:eventName withProperties:nil forTransmissionTarget:target]));
}

- (void)testTrackEventWithProperties {

  // If
  MSAnalyticsTransmissionTarget *target =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken parentTarget:nil];
  NSString *eventName = @"event";
  NSDictionary *properties = @{ @"prop1" : @"val1", @"prop2" : @"val2" };

  // When
  [target trackEvent:eventName withProperties:properties];

  // Then
  XCTAssertTrue(target.eventProperties.count == 0);
  OCMVerify(ClassMethod(
      [self.analyticsClassMock trackEvent:eventName withProperties:properties forTransmissionTarget:target]));
}

- (void)testTransmissionTargetForToken {

  // If
  NSDictionary *properties = [NSDictionary new];
  NSString *event1 = @"event1";
  NSString *event2 = @"event2";
  NSString *event3 = @"event3";

  MSAnalyticsTransmissionTarget *parentTransmissionTarget =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken parentTarget:nil];
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
  OCMVerify(ClassMethod([self.analyticsClassMock trackEvent:event1
                                             withProperties:properties
                                      forTransmissionTarget:childTransmissionTarget]));
  OCMVerify(ClassMethod([self.analyticsClassMock trackEvent:event2
                                             withProperties:properties
                                      forTransmissionTarget:childTransmissionTarget2]));
  OCMVerify(ClassMethod([self.analyticsClassMock trackEvent:event3
                                             withProperties:properties
                                      forTransmissionTarget:childTransmissionTarget3]));
}

- (void)testTransmissionTargetEnabledState {

  // If
  NSDictionary *properties = @{ @"prop1" : @"val1", @"prop2" : @"val2" };
  NSString *event1 = @"event1";
  NSString *event2 = @"event2";
  NSString *event3 = @"event3";
  NSString *event4 = @"event4";

  MSAnalyticsTransmissionTarget *transmissionTarget, *transmissionTarget2;

  // Events tracked when disabled mustn't be sent.
  OCMReject(ClassMethod(
      [self.analyticsClassMock trackEvent:event2 withProperties:properties forTransmissionTarget:transmissionTarget]));
  OCMReject(ClassMethod(
      [self.analyticsClassMock trackEvent:event3 withProperties:properties forTransmissionTarget:transmissionTarget2]));

  // When

  // Target enabled by default.
  transmissionTarget =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken parentTarget:nil];
  [transmissionTarget setEnabled:YES];

  // Then
  XCTAssertTrue([transmissionTarget isEnabled]);
  [transmissionTarget trackEvent:event1 withProperties:properties];

  // When

  // Disabling, track event won't work.
  [transmissionTarget setEnabled:NO];
  [transmissionTarget trackEvent:event2 withProperties:properties];

  // Then
  XCTAssertFalse([transmissionTarget isEnabled]);

  // When

  // Allocating a new object with the same token should return the enabled state for this token.
  transmissionTarget2 =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken parentTarget:nil];
  [transmissionTarget2 trackEvent:event3 withProperties:properties];

  // Then
  XCTAssertFalse([transmissionTarget2 isEnabled]);

  // When

  // Re-enabling
  [transmissionTarget2 setEnabled:YES];
  [transmissionTarget2 trackEvent:event4 withProperties:properties];

  // Then
  XCTAssertTrue([transmissionTarget2 isEnabled]);
  OCMVerify(ClassMethod(
      [self.analyticsClassMock trackEvent:event1 withProperties:properties forTransmissionTarget:transmissionTarget]));
  OCMVerify(ClassMethod(
      [self.analyticsClassMock trackEvent:event4 withProperties:properties forTransmissionTarget:transmissionTarget2]));
}

- (void)testTransmissionTargetNestedEnabledState {

  // If
  MSAnalyticsTransmissionTarget *target =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken parentTarget:nil];

  // When

  // Create a child while parent is enabled, child also enabled.
  MSAnalyticsTransmissionTarget *childTarget = [target transmissionTargetForToken:@"childTarget1-guid"];

  // Then
  XCTAssertTrue([childTarget isEnabled]);

  // If
  MSAnalyticsTransmissionTarget *subChildTarget = [childTarget transmissionTargetForToken:@"subChildTarget1-guid"];

  // When

  // Disabling the parent disables its children.
  [target setEnabled:NO];

  // Then
  XCTAssertFalse([target isEnabled]);
  XCTAssertFalse([childTarget isEnabled]);
  XCTAssertFalse([subChildTarget isEnabled]);

  // When

  // Enabling a child while parent is disabled won't work.
  [childTarget setEnabled:YES];

  // Then
  XCTAssertFalse([target isEnabled]);
  XCTAssertFalse([childTarget isEnabled]);
  XCTAssertFalse([subChildTarget isEnabled]);

  // When

  // Adding another child, it's state should reflect its parent.
  MSAnalyticsTransmissionTarget *childTarget2 = [target transmissionTargetForToken:@"childTarget2-guid"];

  // Then
  XCTAssertFalse([target isEnabled]);
  XCTAssertFalse([childTarget isEnabled]);
  XCTAssertFalse([subChildTarget isEnabled]);
  XCTAssertFalse([childTarget2 isEnabled]);

  // When

  // Enabling a parent enables its children.
  [target setEnabled:YES];

  // Then
  XCTAssertTrue([target isEnabled]);
  XCTAssertTrue([childTarget isEnabled]);
  XCTAssertTrue([subChildTarget isEnabled]);
  XCTAssertTrue([childTarget2 isEnabled]);

  // When

  // Disabling a child only disables its children.
  [childTarget setEnabled:NO];

  // Then
  XCTAssertTrue([target isEnabled]);
  XCTAssertFalse([childTarget isEnabled]);
  XCTAssertFalse([subChildTarget isEnabled]);
  XCTAssertTrue([childTarget2 isEnabled]);
}

- (void)testLongListOfImmediateChildren {

  // If
  short maxChildren = 50;
  NSMutableArray<MSAnalyticsTransmissionTarget *> *childrenTargets;
  MSAnalyticsTransmissionTarget *parentTarget =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken parentTarget:nil];
  for (short i = 1; i <= maxChildren; i++) {
    [childrenTargets
        addObject:[parentTarget transmissionTargetForToken:[NSString stringWithFormat:@"Child%d-guid", i]]];
  }

  // When
  [self measureBlock:^{
    [parentTarget setEnabled:NO];
  }];

  // Then
  XCTAssertFalse(parentTarget.isEnabled);
  for (MSAnalyticsTransmissionTarget *child in childrenTargets) {
    XCTAssertFalse(child.isEnabled);
  }
}

- (void)testLongListOfSubChildren {

  // If
  short maxSubChildren = 50;
  NSMutableArray<MSAnalyticsTransmissionTarget *> *childrenTargets;
  MSAnalyticsTransmissionTarget *parentTarget =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken parentTarget:nil];
  MSAnalyticsTransmissionTarget *currentChildren = [parentTarget transmissionTargetForToken:@"Child1-guid"];
  [childrenTargets addObject:currentChildren];
  for (short i = 2; i <= maxSubChildren; i++) {
    currentChildren = [currentChildren transmissionTargetForToken:[NSString stringWithFormat:@"SubChild%d-guid", i]];
    [childrenTargets addObject:currentChildren];
  }

  // When
  [self measureBlock:^{
    [parentTarget setEnabled:NO];
  }];

  // Then
  XCTAssertFalse(parentTarget.isEnabled);
  for (MSAnalyticsTransmissionTarget *child in childrenTargets) {
    XCTAssertFalse(child.isEnabled);
  }
}

- (void)testSetAndRemoveEventProperty {

  // If
  MSAnalyticsTransmissionTarget *target =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken parentTarget:nil];
  NSString *prop1Key = @"prop1";
  NSString *prop1Value = @"val1";

  // When
  [target removeEventPropertyforKey:prop1Key];

  // Then
  XCTAssertEqualObjects(target.eventProperties, @{});

  // When
  [target setEventPropertyString:prop1Value forKey:prop1Key];

  // Then
  XCTAssertEqualObjects(target.eventProperties, @{prop1Key : prop1Value});

  // If
  NSString *prop2Key = @"prop2";
  NSString *prop2Value = @"val2";

  // When
  [target setEventPropertyString:prop2Value forKey:prop2Key];

  // Then
  XCTAssertEqualObjects(target.eventProperties, (@{prop1Key : prop1Value, prop2Key : prop2Value}));

  // When
  [target removeEventPropertyforKey:prop1Key];

  // Then
  XCTAssertEqualObjects(target.eventProperties, @{prop2Key : prop2Value});
}

- (void)testMergingEventProperties {

  // If

  // Common properties only.
  MSAnalyticsTransmissionTarget *target =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken parentTarget:nil];
  NSString *eventName = @"event";
  NSString *propCommonKey = @"propCommonKey";
  NSString *propCommonValue = @"propCommonValue";
  NSString *propCommonKey2 = @"sharedPropKey";
  NSString *propCommonValue2 = @"propCommonValue2";
  [target setEventPropertyString:propCommonValue forKey:propCommonKey];
  [target setEventPropertyString:propCommonValue2 forKey:propCommonKey2];

  // When
  [target trackEvent:eventName];

  // Then
  id commonProperties = @{propCommonKey : propCommonValue, propCommonKey2 : propCommonValue2};
  XCTAssertEqualObjects(target.eventProperties, commonProperties);
  OCMVerify(ClassMethod(
      [self.analyticsClassMock trackEvent:eventName withProperties:commonProperties forTransmissionTarget:target]));

  // If

  // Both common properties and track event properties.
  NSString *propTrackKey = @"propTrackKey";
  NSString *propTrackValue = @"propTrackValue";
  NSString *propTrackKey2 = @"sharedPropKey";
  NSString *propTrackValue2 = @"propTrackValue2";

  // When
  [target trackEvent:eventName withProperties:@{propTrackKey : propTrackValue, propTrackKey2 : propTrackValue2}];

  // Then
  XCTAssertEqualObjects(target.eventProperties, commonProperties);
  OCMVerify(ClassMethod([self.analyticsClassMock trackEvent:eventName
                                             withProperties:(@{
                                               propCommonKey : propCommonValue,
                                               propTrackKey : propTrackValue,
                                               propTrackKey2 : propTrackValue2
                                             })
                                      forTransmissionTarget:target]));
}

@end
