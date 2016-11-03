#import "MSConstants+Internal.h"
#import "MSFeatureAbstract.h"
#import "MSFeatureAbstractInternal.h"
#import "MSFeatureAbstractPrivate.h"
#import "MSFeatureAbstractProtected.h"
#import "MSFeatureCommon.h"
#import "MSLogManager.h"
#import "MSLogManagerDefault.h"
#import "MSMobileCenter.h"
#import "MSSonomaInternal.h"
#import "MSUserDefaults.h"
#import "MSUtils.h"
#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@interface MSFeatureAbstractImplementation : MSFeatureAbstract <MSFeatureInternal>

@end

@implementation MSFeatureAbstractImplementation

+ (instancetype)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)startWithLogManager:(id<MSLogManager>)logManager {
  [super startWithLogManager:logManager];
}

- (NSString *)storageKey {
  return @"MSFeatureAbstractImplementation";
}

- (MSPriority)priority {
  return MSPriorityDefault;
}

@end

@interface MSFeatureAbstractTest : XCTestCase

@property(nonatomic) id settingsMock;

/**
 *  System Under test
 */
@property(nonatomic) MSFeatureAbstractImplementation *abstractFeature;

@end

@implementation MSFeatureAbstractTest

- (void)setUp {
  [super setUp];

  // Set up the mocked storage.
  self.settingsMock = OCMPartialMock(kMSUserDefaults);

  // System Under Test.
  self.abstractFeature = [[MSFeatureAbstractImplementation alloc] initWithStorage:self.settingsMock];

  // Clean storage.
  [(MSUserDefaults *)self.settingsMock removeObjectForKey:self.abstractFeature.isEnabledKey];
  [(MSUserDefaults *)self.settingsMock removeObjectForKey:kMSCoreIsEnabledKey];
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

  // Mock MSSettings and swizzle its setObject:forKey: method to check what's sent by the sut to the persistence.
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

  assertThatBool([[MSFeatureAbstractImplementation sharedInstance] canBeUsed], isFalse());

  [MSMobileCenter start:[[NSUUID UUID] UUIDString] withFeatures:@[ [MSFeatureAbstractImplementation class] ]];

  assertThatBool([[MSFeatureAbstractImplementation sharedInstance] canBeUsed], isTrue());
}

- (void)testFeatureDisabledOnCoreDisabled {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:kMSCoreIsEnabledKey];
  [MSMobileCenter start:[[NSUUID UUID] UUIDString] withFeatures:@[ [MSFeatureAbstractImplementation class] ]];

  // When
  [MSMobileCenter setEnabled:NO];

  // Then
  assertThatBool([[MSFeatureAbstractImplementation class] isEnabled], isFalse());
}

- (void)testEnableFeatureOnCoreDisabled {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:kMSCoreIsEnabledKey];
  [MSMobileCenter start:[[NSUUID UUID] UUIDString] withFeatures:@[ [MSFeatureAbstractImplementation class] ]];
  [MSMobileCenter setEnabled:NO];

  // When
  [[MSFeatureAbstractImplementation class] setEnabled:YES];

  // Then
  assertThatBool([[MSFeatureAbstractImplementation class] isEnabled], isFalse());
}

- (void)testLogDeletedOnDisabled {

  /**
   *  If
   */
  __block MSPriority priority;
  __block BOOL deleteLogs;
  __block BOOL forwardedEnabled;
  id<MSLogManager> logManagerMock = OCMClassMock([MSLogManagerDefault class]);
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
  id<MSLogManager> logManagerMock = OCMClassMock([MSLogManagerDefault class]);
  self.abstractFeature.logManager = logManagerMock;

  // When
  [self.abstractFeature startWithLogManager:logManagerMock];

  // Then
  OCMVerify([logManagerMock setEnabled:YES andDeleteDataOnDisabled:YES forPriority:self.abstractFeature.priority]);
}

@end
