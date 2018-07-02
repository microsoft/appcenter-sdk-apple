#import "MSAnalyticsInternal.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"

static NSString *const kMSTestTransmissionToken = @"TestTransmissionToken";
static NSString *const kMSTestTransmissionToken2 = @"TestTransmissionToken2";

@interface MSAnalyticsTransmissionTargetTests : XCTestCase

@property(nonatomic) MSMockUserDefaults *storageMock;
@end

@implementation MSAnalyticsTransmissionTargetTests

- (void)setUp {
  [super setUp];
  self.storageMock = [MSMockUserDefaults new];

  // Analytics enabled state can prevent targets from tracking events.
  id AnalyticsClassMock = OCMClassMock([MSAnalytics class]);
  OCMStub(ClassMethod([AnalyticsClassMock isEnabled])).andReturn(YES);
}

#pragma mark - Tests

- (void)testInitialization {

  // When
  MSAnalyticsTransmissionTarget *transmissionTarget =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken
                                                                parentTarget:nil
                                                                     storage:self.storageMock];

  // Then
  XCTAssertNotNil(transmissionTarget);
  XCTAssertEqual(kMSTestTransmissionToken, transmissionTarget.transmissionTargetToken);
}

- (void)testTrackEvent {

  // If
  MSAnalyticsTransmissionTarget *transmissionTarget =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken
                                                                parentTarget:nil
                                                                     storage:self.storageMock];
  NSString *eventName = @"event";

  // When
  [transmissionTarget trackEvent:eventName];

  // Then
  OCMVerify(ClassMethod([MSAnalytics trackEvent:eventName forTransmissionTarget:transmissionTarget]));
}

- (void)testTrackEventWithProperties {

  // If
  MSAnalyticsTransmissionTarget *transmissionTarget =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken
                                                                parentTarget:nil
                                                                     storage:self.storageMock];
  NSString *eventName = @"event";
  NSDictionary *properties = @{ @"prop1" : @"val1", @"prop2" : @"val2" };

  // When
  [transmissionTarget trackEvent:eventName withProperties:properties];

  // Then
  OCMVerify(ClassMethod(
      [MSAnalytics trackEvent:eventName withProperties:properties forTransmissionTarget:transmissionTarget]));
}

- (void)testTransmissionTargetForToken {

  // If
  NSDictionary *properties = [NSDictionary new];
  NSString *event1 = @"event1";
  NSString *event2 = @"event2";
  NSString *event3 = @"event3";

  MSAnalyticsTransmissionTarget *parentTransmissionTarget =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken
                                                                parentTarget:nil
                                                                     storage:self.storageMock];
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

- (void)testTransmissionTargetEnabledState {

  // If
  NSDictionary *properties = @{ @"prop1" : @"val1", @"prop2" : @"val2" };
  NSString *event1 = @"event1";
  NSString *event2 = @"event2";
  NSString *event3 = @"event3";
  NSString *event4 = @"event4";

  MSAnalyticsTransmissionTarget *transmissionTarget, *transmissionTarget2;

  // Events tracked when disabled mustn't be sent.
  OCMReject(
      ClassMethod([MSAnalytics trackEvent:event2 withProperties:properties forTransmissionTarget:transmissionTarget]));
  OCMReject(
      ClassMethod([MSAnalytics trackEvent:event3 withProperties:properties forTransmissionTarget:transmissionTarget2]));

  // When

  // Target enabled by default.
  transmissionTarget = [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken
                                                                                 parentTarget:nil
                                                                                      storage:self.storageMock];
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
  transmissionTarget2 = [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken
                                                                                  parentTarget:nil
                                                                                       storage:self.storageMock];
  [transmissionTarget2 trackEvent:event3 withProperties:properties];

  // Then
  XCTAssertFalse([transmissionTarget2 isEnabled]);

  // When

  // Re-enabling
  [transmissionTarget2 setEnabled:YES];
  [transmissionTarget2 trackEvent:event4 withProperties:properties];

  // Then
  XCTAssertTrue([transmissionTarget2 isEnabled]);
  OCMVerify(
      ClassMethod([MSAnalytics trackEvent:event1 withProperties:properties forTransmissionTarget:transmissionTarget2]));
  OCMVerify(
      ClassMethod([MSAnalytics trackEvent:event4 withProperties:properties forTransmissionTarget:transmissionTarget2]));
}

- (void)testTransmissionTargetNestedEnabledState {

  // If
  MSAnalyticsTransmissionTarget *target =
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken
                                                                parentTarget:nil
                                                                     storage:self.storageMock];

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
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken
                                                                parentTarget:nil
                                                                     storage:self.storageMock];
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
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:kMSTestTransmissionToken
                                                                parentTarget:nil
                                                                     storage:self.storageMock];
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

@end
