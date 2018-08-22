#import "MSAnalyticsAuthenticationProviderInternal.h"
#import "MSAnalyticsInternal.h"
#import "MSAnalyticsPrivate.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSAppCenterInternal.h"
#import "MSChannelUnitDefault.h"
#import "MSChannelUnitProtocol.h"
#import "MSEventLog.h"
#import "MSMockUserDefaults.h"
#import "MSPropertyConfiguratorPrivate.h"
#import "MSTestFrameworks.h"

static NSString *const kMSTestTransmissionToken = @"TestTransmissionToken";
static NSString *const kMSTestTransmissionToken2 = @"TestTransmissionToken2";

@interface MSAnalyticsTransmissionTargetTests : XCTestCase

@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) id analyticsClassMock;
@property(nonatomic) id<MSChannelGroupProtocol> channelGroupMock;

@end

@implementation MSAnalyticsTransmissionTargetTests

- (void)setUp {
  [super setUp];

  // Mock NSUserDefaults
  self.settingsMock = [MSMockUserDefaults new];

  // Analytics enabled state can prevent targets from tracking events.
  self.analyticsClassMock = OCMClassMock([MSAnalytics class]);
  OCMStub(ClassMethod([self.analyticsClassMock isEnabled])).andReturn(YES);
  self.channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
}

- (void)tearDown {
  [self.settingsMock stopMocking];
  [self.analyticsClassMock stopMocking];
  MSAnalyticsTransmissionTarget.authenticationProvider = nil;
  [super tearDown];
}

#pragma mark - Tests

- (void)testInitialization {

  // When
  MSAnalyticsTransmissionTarget *sut =
      [[MSAnalyticsTransmissionTarget alloc]
          initWithTransmissionTargetToken:kMSTestTransmissionToken
                             parentTarget:nil
                             channelGroup:self.channelGroupMock];

  // Then
  XCTAssertNotNil(sut);
  XCTAssertEqual(kMSTestTransmissionToken,
                 sut.transmissionTargetToken);
  XCTAssertEqualObjects(sut.propertyConfigurator.eventProperties,
                        @{});
  XCTAssertNil(MSAnalyticsTransmissionTarget.authenticationProvider);
}

- (void)testTrackEvent {

  // If
  MSAnalyticsTransmissionTarget *sut = [[MSAnalyticsTransmissionTarget alloc]
      initWithTransmissionTargetToken:kMSTestTransmissionToken
                         parentTarget:nil
                         channelGroup:self.channelGroupMock];
  NSString *eventName = @"event";

  // When
  [sut trackEvent:eventName];

  // Then
  XCTAssertTrue(sut.propertyConfigurator.eventProperties.count == 0);
  OCMVerify(ClassMethod([self.analyticsClassMock trackEvent:eventName
                                             withProperties:nil
                                      forTransmissionTarget:sut]));
}

- (void)testTrackEventWithProperties {

  // If
  MSAnalyticsTransmissionTarget *sut = [[MSAnalyticsTransmissionTarget alloc]
      initWithTransmissionTargetToken:kMSTestTransmissionToken
                         parentTarget:nil
                         channelGroup:self.channelGroupMock];
  NSString *eventName = @"event";
  NSDictionary *properties = @{ @"prop1" : @"val1", @"prop2" : @"val2" };

  // When
  [sut trackEvent:eventName withProperties:properties];

  // Then
  XCTAssertTrue(sut.propertyConfigurator.eventProperties.count == 0);
  OCMVerify(ClassMethod([self.analyticsClassMock trackEvent:eventName
                                             withProperties:properties
                                      forTransmissionTarget:sut]));
}

- (void)testTransmissionTargetForToken {

  // If
  NSDictionary *properties = [NSDictionary new];
  NSString *event1 = @"event1";
  NSString *event2 = @"event2";
  NSString *event3 = @"event3";

  MSAnalyticsTransmissionTarget *parentTransmissionTarget =
      [[MSAnalyticsTransmissionTarget alloc]
          initWithTransmissionTargetToken:kMSTestTransmissionToken
                             parentTarget:nil
                             channelGroup:self.channelGroupMock];
  MSAnalyticsTransmissionTarget *childTransmissionTarget;

  // When
  childTransmissionTarget = [parentTransmissionTarget
      transmissionTargetForToken:kMSTestTransmissionToken2];
  [childTransmissionTarget trackEvent:event1 withProperties:properties];

  // Then
  XCTAssertEqualObjects(kMSTestTransmissionToken2,
                        childTransmissionTarget.transmissionTargetToken);
  XCTAssertEqualObjects(
      childTransmissionTarget,
      parentTransmissionTarget
          .childTransmissionTargets[kMSTestTransmissionToken2]);

  // When
  MSAnalyticsTransmissionTarget *childTransmissionTarget2 =
      [parentTransmissionTarget
          transmissionTargetForToken:kMSTestTransmissionToken2];
  [childTransmissionTarget2 trackEvent:event2 withProperties:properties];

  // Then
  XCTAssertEqualObjects(childTransmissionTarget, childTransmissionTarget2);
  XCTAssertEqualObjects(
      childTransmissionTarget2,
      parentTransmissionTarget
          .childTransmissionTargets[kMSTestTransmissionToken2]);

  // When
  MSAnalyticsTransmissionTarget *childTransmissionTarget3 =
      [parentTransmissionTarget
          transmissionTargetForToken:kMSTestTransmissionToken];
  [childTransmissionTarget3 trackEvent:event3 withProperties:properties];

  // Then
  XCTAssertNotEqualObjects(parentTransmissionTarget, childTransmissionTarget3);
  XCTAssertEqualObjects(
      childTransmissionTarget3,
      parentTransmissionTarget
          .childTransmissionTargets[kMSTestTransmissionToken]);
  OCMVerify(ClassMethod([self.analyticsClassMock
                 trackEvent:event1
             withProperties:properties
      forTransmissionTarget:childTransmissionTarget]));
  OCMVerify(ClassMethod([self.analyticsClassMock
                 trackEvent:event2
             withProperties:properties
      forTransmissionTarget:childTransmissionTarget2]));
  OCMVerify(ClassMethod([self.analyticsClassMock
                 trackEvent:event3
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
  OCMReject(
      ClassMethod([self.analyticsClassMock trackEvent:event2
                                       withProperties:properties
                                forTransmissionTarget:transmissionTarget]));
  OCMReject(
      ClassMethod([self.analyticsClassMock trackEvent:event3
                                       withProperties:properties
                                forTransmissionTarget:transmissionTarget2]));

  // When

  // Target enabled by default.
  transmissionTarget = [[MSAnalyticsTransmissionTarget alloc]
      initWithTransmissionTargetToken:kMSTestTransmissionToken
                         parentTarget:nil
                         channelGroup:self.channelGroupMock];
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

  // Allocating a new object with the same token should return the enabled state
  // for this token.
  transmissionTarget2 = [[MSAnalyticsTransmissionTarget alloc]
      initWithTransmissionTargetToken:kMSTestTransmissionToken
                         parentTarget:nil
                         channelGroup:self.channelGroupMock];
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
      ClassMethod([self.analyticsClassMock trackEvent:event1
                                       withProperties:properties
                                forTransmissionTarget:transmissionTarget]));
  OCMVerify(
      ClassMethod([self.analyticsClassMock trackEvent:event4
                                       withProperties:properties
                                forTransmissionTarget:transmissionTarget2]));
}

- (void)testTransmissionTargetNestedEnabledState {

  // If
  MSAnalyticsTransmissionTarget *target = [[MSAnalyticsTransmissionTarget alloc]
      initWithTransmissionTargetToken:kMSTestTransmissionToken
                         parentTarget:nil
                         channelGroup:self.channelGroupMock];

  // When

  // Create a child while parent is enabled, child also enabled.
  MSAnalyticsTransmissionTarget *childTarget =
      [target transmissionTargetForToken:@"childTarget1-guid"];

  // Then
  XCTAssertTrue([childTarget isEnabled]);

  // If
  MSAnalyticsTransmissionTarget *subChildTarget =
      [childTarget transmissionTargetForToken:@"subChildTarget1-guid"];

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
  MSAnalyticsTransmissionTarget *childTarget2 =
      [target transmissionTargetForToken:@"childTarget2-guid"];

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
      [[MSAnalyticsTransmissionTarget alloc]
          initWithTransmissionTargetToken:kMSTestTransmissionToken
                             parentTarget:nil
                             channelGroup:self.channelGroupMock];
  for (short i = 1; i <= maxChildren; i++) {
    [childrenTargets
        addObject:[parentTarget
                      transmissionTargetForToken:
                          [NSString stringWithFormat:@"Child%d-guid", i]]];
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
      [[MSAnalyticsTransmissionTarget alloc]
          initWithTransmissionTargetToken:kMSTestTransmissionToken
                             parentTarget:nil
                             channelGroup:self.channelGroupMock];
  MSAnalyticsTransmissionTarget *currentChildren =
      [parentTarget transmissionTargetForToken:@"Child1-guid"];
  [childrenTargets addObject:currentChildren];
  for (short i = 2; i <= maxSubChildren; i++) {
    currentChildren = [currentChildren
        transmissionTargetForToken:[NSString
                                       stringWithFormat:@"SubChild%d-guid", i]];
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
  MSAnalyticsTransmissionTarget *targetMock =
      [[MSAnalyticsTransmissionTarget alloc]
          initWithTransmissionTargetToken:kMSTestTransmissionToken
                             parentTarget:nil
                             channelGroup:self.channelGroupMock];
  MSPropertyConfigurator *configurator =
      [[MSPropertyConfigurator alloc] initWithTransmissionTarget:targetMock];

  NSString *prop1Key = @"prop1";
  NSString *prop1Value = @"val1";

  // When
  [configurator removeEventPropertyForKey:prop1Key];

  // Then
  XCTAssertEqualObjects(configurator.eventProperties, @{});

  // When
  [configurator removeEventPropertyForKey:nil];

  // Then
  XCTAssertEqualObjects(configurator.eventProperties, @{});

  // When
  [configurator setEventPropertyString:nil forKey:prop1Key];

  // Then
  XCTAssertEqualObjects(configurator.eventProperties, @{});

  // When
  [configurator setEventPropertyString:prop1Value forKey:nil];

  // Then
  XCTAssertEqualObjects(configurator.eventProperties, @{});

  // When
  [configurator setEventPropertyString:prop1Value forKey:prop1Key];

  // Then
  XCTAssertEqualObjects(configurator.eventProperties, @{prop1Key : prop1Value});

  // If
  NSString *prop2Key = @"prop2";
  NSString *prop2Value = @"val2";

  // When
  [configurator setEventPropertyString:prop2Value forKey:prop2Key];

  // Then
  XCTAssertEqualObjects(configurator.eventProperties,
                        (@{prop1Key : prop1Value, prop2Key : prop2Value}));

  // When
  [configurator removeEventPropertyForKey:prop1Key];

  // Then
  XCTAssertEqualObjects(configurator.eventProperties, @{prop2Key : prop2Value});
}

- (void)testMergingEventProperties {

  // If

  // Common properties only.
  MSAnalyticsTransmissionTarget *target = [[MSAnalyticsTransmissionTarget alloc]
      initWithTransmissionTargetToken:kMSTestTransmissionToken
                         parentTarget:nil
                         channelGroup:self.channelGroupMock];
  NSString *eventName = @"event";
  NSString *propCommonKey = @"propCommonKey";
  NSString *propCommonValue = @"propCommonValue";
  NSString *propCommonKey2 = @"sharedPropKey";
  NSString *propCommonValue2 = @"propCommonValue2";
  [target.propertyConfigurator setEventPropertyString:propCommonValue
                                               forKey:propCommonKey];
  [target.propertyConfigurator setEventPropertyString:propCommonValue2
                                               forKey:propCommonKey2];

  // When
  [target trackEvent:eventName];

  // Then
  id commonProperties =
      @{propCommonKey : propCommonValue, propCommonKey2 : propCommonValue2};
  XCTAssertEqualObjects(target.propertyConfigurator.eventProperties,
                        commonProperties);
  OCMVerify(ClassMethod([self.analyticsClassMock trackEvent:eventName
                                             withProperties:commonProperties
                                      forTransmissionTarget:target]));

  // If

  // Both common properties and track event properties.
  NSString *propTrackKey = @"propTrackKey";
  NSString *propTrackValue = @"propTrackValue";
  NSString *propTrackKey2 = @"sharedPropKey";
  NSString *propTrackValue2 = @"propTrackValue2";

  // When
  [target trackEvent:eventName
      withProperties:@{
        propTrackKey : propTrackValue,
        propTrackKey2 : propTrackValue2
      }];

  // Then
  XCTAssertEqualObjects(target.propertyConfigurator.eventProperties,
                        commonProperties);
  OCMVerify(ClassMethod([self.analyticsClassMock trackEvent:eventName
                                             withProperties:(@{
                                               propCommonKey : propCommonValue,
                                               propTrackKey : propTrackValue,
                                               propTrackKey2 : propTrackValue2
                                             })forTransmissionTarget:target]));
}

- (void)testEventPropertiesCascading {

  // If
  [MSAnalytics resetSharedInstance];
  id<MSChannelUnitProtocol> channelUnitMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([self.channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [MSAppCenter sharedInstance].sdkConfigured = YES;
  [[MSAnalytics sharedInstance] startWithChannelGroup:self.channelGroupMock
                                            appSecret:@"appsecret"
                              transmissionTargetToken:@"token"
                                      fromApplication:YES];

  // Prepare target instances.
  MSAnalyticsTransmissionTarget *grandParent =
      [MSAnalytics transmissionTargetForToken:@"grand-parent"];
  MSAnalyticsTransmissionTarget *parent =
      [grandParent transmissionTargetForToken:@"parent"];
  MSAnalyticsTransmissionTarget *child =
      [parent transmissionTargetForToken:@"child"];

  // Set properties to grand parent.
  [grandParent.propertyConfigurator setEventPropertyString:@"1" forKey:@"a"];
  [grandParent.propertyConfigurator setEventPropertyString:@"2" forKey:@"b"];
  [grandParent.propertyConfigurator setEventPropertyString:@"3" forKey:@"c"];

  // Override some properties.
  [parent.propertyConfigurator setEventPropertyString:@"11" forKey:@"a"];
  [parent.propertyConfigurator setEventPropertyString:@"22" forKey:@"b"];

  // Set a new property in parent.
  [parent.propertyConfigurator setEventPropertyString:@"44" forKey:@"d"];

  // Just to show we still get value from parent which is inherited from grand
  // parent, if we remove an override. */
  [parent.propertyConfigurator setEventPropertyString:@"33" forKey:@"c"];
  [parent.propertyConfigurator removeEventPropertyForKey:@"c"];

  // Override a property.
  [child.propertyConfigurator setEventPropertyString:@"444" forKey:@"d"];

  // Set new properties in child.
  [child.propertyConfigurator setEventPropertyString:@"555" forKey:@"e"];
  [child.propertyConfigurator setEventPropertyString:@"666" forKey:@"f"];

  // Track event in child. Override some properties in trackEvent.
  NSMutableDictionary<NSString *, NSString *> *properties =
      [NSMutableDictionary new];
  [properties setValue:@"6666" forKey:@"f"];
  [properties setValue:@"7777" forKey:@"g"];

  // Mock channel group.
  __block MSEventLog *eventLog;
  OCMStub([channelUnitMock enqueueItem:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        id<MSLog> log = nil;
        [invocation getArgument:&log atIndex:2];
        eventLog = (MSEventLog *)log;
      });

  // When
  [child trackEvent:@"eventName" withProperties:properties];

  // Then
  XCTAssertNotNil(eventLog);
  XCTAssertEqual([eventLog.properties count], (unsigned long)7);
  XCTAssertEqual(eventLog.properties[@"a"], @"11");
  XCTAssertEqual(eventLog.properties[@"b"], @"22");
  XCTAssertEqual(eventLog.properties[@"c"], @"3");
  XCTAssertEqual(eventLog.properties[@"d"], @"444");
  XCTAssertEqual(eventLog.properties[@"e"], @"555");
  XCTAssertEqual(eventLog.properties[@"f"], @"6666");
  XCTAssertEqual(eventLog.properties[@"g"], @"7777");
}

- (void)testAppExtentionCommonSchemaPropertiesWithoutOverriding {

  // If

  // Prepare target instance.
  MSAnalyticsTransmissionTarget *target =
      [MSAnalytics transmissionTargetForToken:@"target"];

  // Set a log.
  MSCommonSchemaLog *log = [MSCommonSchemaLog new];
  log.ext = [MSCSExtensions new];
  log.ext.appExt = [MSAppExtension new];
  log.ext.appExt.ver = @"0.0.1";
  log.ext.appExt.name = @"baseAppName";
  log.ext.appExt.locale = @"en-us";

  // When
  [target.propertyConfigurator channel:nil prepareLog:log];

  // Then
  XCTAssertNil(target.propertyConfigurator.appVersion);
  XCTAssertNil(target.propertyConfigurator.appName);
  XCTAssertNil(target.propertyConfigurator.appLocale);
  XCTAssertEqual(log.ext.appExt.ver, @"0.0.1");
  XCTAssertEqual(log.ext.appExt.name, @"baseAppName");
  XCTAssertEqual(log.ext.appExt.locale, @"en-us");
}

- (void)testOverridingDefaultCommonSchemaProperties {

  // If

  // Prepare target instances.
  MSAnalyticsTransmissionTarget *parent =
      [MSAnalytics transmissionTargetForToken:@"parent"];
  MSAnalyticsTransmissionTarget *child =
      [parent transmissionTargetForToken:@"child"];

  // Set properties to grand parent.
  [parent.propertyConfigurator setAppVersion:@"8.4.1"];
  [parent.propertyConfigurator setAppName:@"ParentAppName"];
  [parent.propertyConfigurator setAppLocale:@"en-us"];

  // Set a log with default values.
  MSCommonSchemaLog *log = [MSCommonSchemaLog new];
  log.ext = [MSCSExtensions new];
  log.ext.appExt = [MSAppExtension new];
  [log addTransmissionTargetToken:@"parent"];
  [log addTransmissionTargetToken:@"child"];

  // When
  [child.propertyConfigurator channel:nil prepareLog:log];

  // Then
  XCTAssertEqual(log.ext.appExt.ver, parent.propertyConfigurator.appVersion);
  XCTAssertEqual(log.ext.appExt.name, parent.propertyConfigurator.appName);
  XCTAssertEqual(log.ext.appExt.locale, parent.propertyConfigurator.appLocale);
}

- (void)testOverridingCommonSchemaProperties {

  // If

  // Prepare target instance.
  MSAnalyticsTransmissionTarget *target =
      [MSAnalytics transmissionTargetForToken:@"target"];

  // Set properties to the target.
  [target.propertyConfigurator setAppVersion:@"8.4.1"];
  [target.propertyConfigurator setAppName:@"NewAppName"];
  [target.propertyConfigurator setAppLocale:@"en-us"];

  // Set a log.
  MSCommonSchemaLog *log = [MSCommonSchemaLog new];
  [log addTransmissionTargetToken:@"target"];
  log.ext = [MSCSExtensions new];
  log.ext.appExt = [MSAppExtension new];
  log.ext.appExt.ver = @"0.0.1";
  log.ext.appExt.name = @"baseAppName";
  log.ext.appExt.locale = @"zh-cn";

  // When
  [target.propertyConfigurator channel:nil prepareLog:log];

  // Then
  XCTAssertEqual(log.ext.appExt.ver, target.propertyConfigurator.appVersion);
  XCTAssertEqual(log.ext.appExt.name, target.propertyConfigurator.appName);
  XCTAssertEqual(log.ext.appExt.locale, target.propertyConfigurator.appLocale);
}

- (void)testOverridingCommonSchemaPropertiesFromParent {

  // If

  // Prepare target instances.
  MSAnalyticsTransmissionTarget *parent =
      [MSAnalytics transmissionTargetForToken:@"parent"];
  MSAnalyticsTransmissionTarget *child =
      [parent transmissionTargetForToken:@"child"];

  // Set properties to grand parent.
  [parent.propertyConfigurator setAppVersion:@"8.4.1"];
  [parent.propertyConfigurator setAppName:@"ParentAppName"];
  [parent.propertyConfigurator setAppLocale:@"en-us"];

  // Set a log.
  MSCommonSchemaLog *log = [MSCommonSchemaLog new];
  log.ext = [MSCSExtensions new];
  log.ext.appExt = [MSAppExtension new];
  log.ext.appExt.ver = @"0.0.1";
  log.ext.appExt.name = @"baseAppName";
  log.ext.appExt.locale = @"zh-cn";
  [log addTransmissionTargetToken:@"parent"];
  [log addTransmissionTargetToken:@"child"];

  // When
  [child.propertyConfigurator channel:nil prepareLog:log];

  // Then
  XCTAssertEqual(log.ext.appExt.ver, parent.propertyConfigurator.appVersion);
  XCTAssertEqual(log.ext.appExt.name, parent.propertyConfigurator.appName);
  XCTAssertEqual(log.ext.appExt.locale, parent.propertyConfigurator.appLocale);
}

- (void)testOverridingCommonSchemaPropertiesDoNothingWhenTargetIsDisabled {

  // If

  // Prepare target instances.
  MSAnalyticsTransmissionTarget *grandParent =
      [MSAnalytics transmissionTargetForToken:@"grand-parent"];
  MSAnalyticsTransmissionTarget *parent =
      [grandParent transmissionTargetForToken:@"parent"];
  MSAnalyticsTransmissionTarget *child =
      [parent transmissionTargetForToken:@"child"];

  // Set properties to grand parent.
  [grandParent.propertyConfigurator setAppVersion:@"8.4.1"];
  [grandParent.propertyConfigurator setAppName:@"GrandParentAppName"];
  [grandParent.propertyConfigurator setAppLocale:@"en-us"];

  // Set common properties to child.
  [child.propertyConfigurator setAppVersion:@"1.4.8"];
  [child.propertyConfigurator setAppName:@"ChildAppName"];
  [child.propertyConfigurator setAppLocale:@"fr-ca"];

  // Set a log.
  MSCommonSchemaLog *log = [MSCommonSchemaLog new];
  log.ext = [MSCSExtensions new];
  log.ext.appExt = [MSAppExtension new];
  log.ext.appExt.ver = @"0.0.1";
  log.ext.appExt.name = @"baseAppName";
  log.ext.appExt.locale = @"zh-cn";
  [log addTransmissionTargetToken:@"parent"];
  [log addTransmissionTargetToken:@"child"];
  [log addTransmissionTargetToken:@"grand-parent"];

  [grandParent setEnabled:NO];

  // When
  [grandParent.propertyConfigurator channel:nil prepareLog:log];

  // Then
  XCTAssertEqual(log.ext.appExt.ver, @"0.0.1");
  XCTAssertEqual(log.ext.appExt.name, @"baseAppName");
  XCTAssertEqual(log.ext.appExt.locale, @"zh-cn");

  // If
  [child setEnabled:NO];

  // When
  [child.propertyConfigurator channel:nil prepareLog:log];

  // Then
  XCTAssertNotEqual(log.ext.appExt.ver, child.propertyConfigurator.appVersion);
  XCTAssertNotEqual(log.ext.appExt.name, child.propertyConfigurator.appName);
  XCTAssertNotEqual(log.ext.appExt.locale,
                    child.propertyConfigurator.appLocale);

  // If

  // Reset a log.
  log = [MSCommonSchemaLog new];
  log.ext = [MSCSExtensions new];
  log.ext.appExt = [MSAppExtension new];
  log.ext.appExt.ver = @"0.0.1";
  log.ext.appExt.name = @"baseAppName";
  log.ext.appExt.locale = @"zh-cn";
  [log addTransmissionTargetToken:@"parent"];
  [log addTransmissionTargetToken:@"child"];
  [log addTransmissionTargetToken:@"grand-parent"];

  // When
  [parent.propertyConfigurator channel:nil prepareLog:log];

  // Then
  XCTAssertEqual(log.ext.appExt.ver, @"0.0.1");
  XCTAssertEqual(log.ext.appExt.name, @"baseAppName");
  XCTAssertEqual(log.ext.appExt.locale, @"zh-cn");
}

- (void)testOverridingCommonSchemaPropertiesWithTwoChildrenUnderTheSameParent {

  // If
  // Prepare target instances.
  MSAnalyticsTransmissionTarget *parent =
      [MSAnalytics transmissionTargetForToken:@"parent"];
  MSAnalyticsTransmissionTarget *child1 =
      [parent transmissionTargetForToken:@"child1"];
  MSAnalyticsTransmissionTarget *child2 =
      [parent transmissionTargetForToken:@"child2"];

  // Set properties to grand parent.
  [parent.propertyConfigurator setAppVersion:@"8.4.1"];
  [parent.propertyConfigurator setAppName:@"ParentAppName"];
  [parent.propertyConfigurator setAppLocale:@"en-us"];

  // Set common properties to child1.
  [child1.propertyConfigurator setAppVersion:@"1.4.8"];
  [child1.propertyConfigurator setAppName:@"Child1AppName"];
  [child1.propertyConfigurator setAppLocale:@"fr-ca"];

  // Set log1.
  MSCommonSchemaLog *log1 = [MSCommonSchemaLog new];
  log1.ext = [MSCSExtensions new];
  log1.ext.appExt = [MSAppExtension new];
  log1.ext.appExt.ver = @"0.0.1";
  log1.ext.appExt.name = @"base1AppName";
  log1.ext.appExt.locale = @"zh-cn";
  [log1 addTransmissionTargetToken:@"parent"];
  [log1 addTransmissionTargetToken:@"child1"];
  [log1 addTransmissionTargetToken:@"child2"];

  // When
  [parent.propertyConfigurator channel:nil prepareLog:log1];

  // Then
  XCTAssertEqual(log1.ext.appExt.ver, parent.propertyConfigurator.appVersion);
  XCTAssertEqual(log1.ext.appExt.name, parent.propertyConfigurator.appName);
  XCTAssertEqual(log1.ext.appExt.locale, parent.propertyConfigurator.appLocale);

  // When
  [child1.propertyConfigurator channel:nil prepareLog:log1];

  // Then
  XCTAssertEqual(log1.ext.appExt.ver, child1.propertyConfigurator.appVersion);
  XCTAssertEqual(log1.ext.appExt.name, child1.propertyConfigurator.appName);
  XCTAssertEqual(log1.ext.appExt.locale, child1.propertyConfigurator.appLocale);
  XCTAssertNotEqual(log1.ext.appExt.ver,
                    parent.propertyConfigurator.appVersion);
  XCTAssertNotEqual(log1.ext.appExt.name, parent.propertyConfigurator.appName);
  XCTAssertNotEqual(log1.ext.appExt.locale,
                    parent.propertyConfigurator.appLocale);
  XCTAssertNil(child2.propertyConfigurator.appVersion);
  XCTAssertNil(child2.propertyConfigurator.appName);
  XCTAssertNil(child2.propertyConfigurator.appLocale);

  // If
  MSCommonSchemaLog *log2 = [MSCommonSchemaLog new];
  log2.ext = [MSCSExtensions new];
  log2.ext.appExt = [MSAppExtension new];
  log2.ext.appExt.ver = @"0.0.2";
  log2.ext.appExt.name = @"base2AppName";
  log2.ext.appExt.locale = @"en-us";
  [log2 addTransmissionTargetToken:@"parent"];
  [log2 addTransmissionTargetToken:@"child1"];
  [log2 addTransmissionTargetToken:@"child2"];

  // When
  [child2.propertyConfigurator channel:nil prepareLog:log2];

  // Then
  XCTAssertEqual(log2.ext.appExt.ver, parent.propertyConfigurator.appVersion);
  XCTAssertEqual(log2.ext.appExt.name, parent.propertyConfigurator.appName);
  XCTAssertEqual(log2.ext.appExt.locale, parent.propertyConfigurator.appLocale);
  XCTAssertNotEqual(log2.ext.appExt.ver,
                    child1.propertyConfigurator.appVersion);
  XCTAssertNotEqual(log2.ext.appExt.name, child1.propertyConfigurator.appName);
  XCTAssertNotEqual(log2.ext.appExt.locale,
                    child1.propertyConfigurator.appLocale);
}

- (void)testAddAuthenticationProvider {
  
  // If
  MSAnalyticsAuthenticationProvider *provider = [[MSAnalyticsAuthenticationProvider alloc] initWithAuthenticationType:MSAnalyticsAuthenticationTypeMsaCompact ticketKey:@"ticketKey" delegate:OCMOCK_ANY];

  // When
  [MSAnalyticsTransmissionTarget addAuthenticationProvider:provider];
  
  // Then
  XCTAssertNotNil(MSAnalyticsTransmissionTarget.authenticationProvider);
  XCTAssertEqual(provider, MSAnalyticsTransmissionTarget.authenticationProvider);
  
  // If
  MSAnalyticsAuthenticationProvider *provider2 = [[MSAnalyticsAuthenticationProvider alloc] initWithAuthenticationType:MSAnalyticsAuthenticationTypeMsaDelegate ticketKey:@"ticketKey2" delegate:OCMOCK_ANY];

  // When
  dispatch_async(dispatch_get_main_queue(), ^{
    [MSAnalyticsTransmissionTarget addAuthenticationProvider:provider2];
  });
  [MSAnalyticsTransmissionTarget addAuthenticationProvider:provider];
  dispatch_async(dispatch_get_main_queue(), ^{
    [MSAnalyticsTransmissionTarget addAuthenticationProvider:provider2];
  });
  
  // Then
  XCTAssertEqual(provider, MSAnalyticsTransmissionTarget.authenticationProvider);
}

@end
