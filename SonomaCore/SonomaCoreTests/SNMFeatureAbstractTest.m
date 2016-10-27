#import "SNMConstants+Internal.h"
#import "SNMFeatureAbstract.h"
#import "SNMFeatureAbstractInternal.h"
#import "SNMFeatureAbstractPrivate.h"
#import "SNMFeatureAbstractProtected.h"
#import "SNMFeatureCommon.h"
#import "SNMLogManager.h"
#import "SNMLogManagerDefault.h"
#import "SNMSonoma.h"
#import "SNMSonomaInternal.h"
#import "SNMUserDefaults.h"
#import "SNMUtils.h"
#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@interface SNMFeatureAbstractImplementation : SNMFeatureAbstract <SNMFeatureInternal>

@end

@implementation SNMFeatureAbstractImplementation

+ (instancetype)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)startWithLogManager:(id<SNMLogManager>)logManager {
  [super startWithLogManager:logManager];
}

- (NSString *)storageKey {
  return @"SNMFeatureAbstractImplementation";
}

- (SNMPriority)priority {
  return SNMPriorityDefault;
}

@end

@interface SNMFeatureAbstractTest : XCTestCase

@property(nonatomic) id settingsMock;

/**
 *  System Under test
 */
@property(nonatomic) SNMFeatureAbstractImplementation *abstractFeature;

@end

@implementation SNMFeatureAbstractTest

- (void)setUp {
  [super setUp];

  // Set up the mocked storage.
  self.settingsMock = OCMPartialMock(kSNMUserDefaults);

  // System Under Test.
  self.abstractFeature = [[SNMFeatureAbstractImplementation alloc] initWithStorage:self.settingsMock];

  // Clean storage.
  [(SNMUserDefaults *)self.settingsMock removeObjectForKey:self.abstractFeature.isEnabledKey];
  [(SNMUserDefaults *)self.settingsMock removeObjectForKey:kSNMCoreIsEnabledKey];
}

- (void)tearDown {
  [super tearDown];

  [self.settingsMock stopMocking];
}

- (void)testIsEnabledTrueByDefault {

  // When
  BOOL isEnabled = [self.abstractFeature isEnabled];

  // Then
  assertThatBool(isEnabled, isTrue());
}

- (void)testSetEnabledToFalse {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:self.abstractFeature.isEnabledKey];
  [self.abstractFeature setEnabled:NO];

  // When
  bool isEnabled = [self.abstractFeature isEnabled];

  // Then
  assertThatBool(isEnabled, isFalse());
}

- (void)testSetEnabledToTrue {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:NO] forKey:self.abstractFeature.isEnabledKey];
  [self.abstractFeature setEnabled:YES];

  // When
  bool isEnabled = [self.abstractFeature isEnabled];

  // Then
  assertThatBool(isEnabled, isTrue());
}

- (void)testIsEnabledToPersistence {

  /**
   *  If
   */
  __block NSNumber *isEnabled;
  BOOL expected = NO;

  // Mock SNMSettings and swizzle its setObject:forKey: method to check what's sent by the sut to the persistence.
  OCMStub([self.settingsMock objectForKey:[OCMArg any]]).andReturn([NSNumber numberWithBool:YES]);
  OCMStub([self.settingsMock setObject:[OCMArg any] forKey:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&isEnabled atIndex:2];
  });

  /**
   *  When
   */
  [self.abstractFeature setEnabled:expected];

  /**
   *  Then
   */
  assertThat(isEnabled, is([NSNumber numberWithBool:expected]));

  // Also check that the sut did access the persistence.
  OCMVerify([self.settingsMock setObject:[OCMArg any] forKey:[OCMArg any]]);
}

- (void)testIsEnabledFromPersistence {

  /**
   *  If
   */
  NSNumber *expected = [NSNumber numberWithBool:NO];
  OCMStub([self.settingsMock objectForKey:[OCMArg any]]).andReturn(expected);

  /**
   *  When
   */
  BOOL isEnabled = [self.abstractFeature isEnabled];

  /**
   *  Then
   */
  assertThat([NSNumber numberWithBool:isEnabled], is(expected));

  // Also check that the sut did access the persistence.
  OCMVerify([self.settingsMock objectForKey:[OCMArg any]]);
}

- (void)testCanBeUsed {

  assertThatBool([[SNMFeatureAbstractImplementation sharedInstance] canBeUsed], isFalse());

  [SNMSonoma start:[[NSUUID UUID] UUIDString] withFeatures:@[ [SNMFeatureAbstractImplementation class] ]];

  assertThatBool([[SNMFeatureAbstractImplementation sharedInstance] canBeUsed], isTrue());
}

- (void)testFeatureDisabledOnCoreDisabled {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:kSNMCoreIsEnabledKey];
  [SNMSonoma start:[[NSUUID UUID] UUIDString] withFeatures:@[ [SNMFeatureAbstractImplementation class] ]];

  // When
  [SNMSonoma setEnabled:NO];

  // Then
  assertThatBool([[SNMFeatureAbstractImplementation class] isEnabled], isFalse());
}

- (void)testEnableFeatureOnCoreDisabled {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:kSNMCoreIsEnabledKey];
  [SNMSonoma start:[[NSUUID UUID] UUIDString] withFeatures:@[ [SNMFeatureAbstractImplementation class] ]];
  [SNMSonoma setEnabled:NO];

  // When
  [[SNMFeatureAbstractImplementation class] setEnabled:YES];

  // Then
  assertThatBool([[SNMFeatureAbstractImplementation class] isEnabled], isFalse());
}

- (void)testLogDeletedOnDisabled {

  /**
   *  If
   */
  __block SNMPriority priority;
  __block BOOL deleteLogs;
  __block BOOL forwardedEnabled;
  id<SNMLogManager> logManagerMock = OCMClassMock([SNMLogManagerDefault class]);
  OCMStub([logManagerMock setEnabled:NO andDeleteDataOnDisabled:YES forPriority:self.abstractFeature.priority])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&priority atIndex:4];
        [invocation getArgument:&deleteLogs atIndex:3];
        [invocation getArgument:&forwardedEnabled atIndex:2];
      });
  self.abstractFeature.logManager = logManagerMock;
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:self.abstractFeature.isEnabledKey];

  /**
   *  When
   */
  [self.abstractFeature setEnabled:NO];

  /**
   *  Then
   */

  // Check that log deletion has been triggered.
  OCMVerify([logManagerMock setEnabled:NO andDeleteDataOnDisabled:YES forPriority:self.abstractFeature.priority]);

  // Priority from the feature must match priority used to delete logs.
  assertThatBool((self.abstractFeature.priority == priority), isTrue());

  // Must request for deletion.
  assertThatBool(deleteLogs, isTrue());

  // Must request for disabling.
  assertThatBool(forwardedEnabled, isFalse());
}

- (void)testEnableLogManagerOnstartWithLogManager {

  // If
  id<SNMLogManager> logManagerMock = OCMClassMock([SNMLogManagerDefault class]);
  self.abstractFeature.logManager = logManagerMock;

  // When
  [self.abstractFeature startWithLogManager:logManagerMock];

  // Then
  OCMVerify([logManagerMock setEnabled:YES andDeleteDataOnDisabled:YES forPriority:self.abstractFeature.priority]);
}

@end
