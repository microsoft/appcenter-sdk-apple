#import "MSConstants+Internal.h"
#import "MSLogManager.h"
#import "MSLogManagerDefault.h"
#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"
#import "MSMobileCenterPrivate.h"
#import "MSServiceAbstractPrivate.h"
#import "MSServiceAbstractProtected.h"
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@interface MSServiceAbstractImplementation : MSServiceAbstract <MSServiceInternal>

@end

@implementation MSServiceAbstractImplementation

+ (instancetype)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)startWithLogManager:(id <MSLogManager>)logManager appSecret:(NSString *)appSecret {
  [super startWithLogManager:logManager appSecret:appSecret];
}

- (NSString *)storageKey {
  return @"MSServiceAbstractImplementation";
}

- (MSPriority)priority {
  return MSPriorityDefault;
}

- (MSInitializationPriority)initializationPriority {
  return MSInitializationPriorityDefault;
}

+ (NSString *)logTag {
  return @"MSServiceAbstractTest";
}

@end

@interface MSServiceAbstractTest : XCTestCase

@property(nonatomic) id settingsMock;

/**
 *  System Under test
 */
@property(nonatomic) MSServiceAbstractImplementation *abstractService;

@end

@implementation MSServiceAbstractTest

- (void)setUp {
  [super setUp];

  // Set up the mocked storage.
  self.settingsMock = OCMPartialMock(MS_USER_DEFAULTS);

  // System Under Test.
  self.abstractService = [[MSServiceAbstractImplementation alloc] initWithStorage:self.settingsMock];

  // Clean storage.
  [(MSUserDefaults *) self.settingsMock removeObjectForKey:self.abstractService.isEnabledKey];
  [(MSUserDefaults *) self.settingsMock removeObjectForKey:kMSMobileCenterIsEnabledKey];
}

- (void)tearDown {
  [super tearDown];

  [self.settingsMock stopMocking];
}

- (void)testIsEnabledTrueByDefault {

  // When
  BOOL isEnabled = [self.abstractService isEnabled];

  // Then
  assertThatBool(isEnabled, isTrue());
}

- (void)testDisableService {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:NO];

  // Then
  assertThatBool([self.abstractService isEnabled], isFalse());
}

- (void)testEnableService {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:NO] forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:YES];

  // Then
  assertThatBool([self.abstractService isEnabled], isTrue());
}

- (void)testDisableServiceOnServiceDisabled {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:NO] forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:NO];

  // Then
  assertThatBool([self.abstractService isEnabled], isFalse());
}

- (void)testEnableServiceOnServiceEnabled {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:YES];

  // Then
  assertThatBool([self.abstractService isEnabled], isTrue());
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
  [self.abstractService setEnabled:expected];

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
  BOOL isEnabled = [self.abstractService isEnabled];

  /**
   *  Then
   */
  assertThat([NSNumber numberWithBool:isEnabled], is(expected));

  // Also check that the sut did access the persistence.
  OCMVerify([self.settingsMock objectForKey:[OCMArg any]]);
}

- (void)testCanBeUsed {
  [MSMobileCenter resetSharedInstance];

  assertThatBool([[MSServiceAbstractImplementation sharedInstance] canBeUsed], isFalse());

  [MSMobileCenter start:MS_UUID_STRING withServices:@[[MSServiceAbstractImplementation class]]];

  assertThatBool([[MSServiceAbstractImplementation sharedInstance] canBeUsed], isTrue());
}

- (void)testEnableServiceOnCoreDisabled {

  // If
  [MSMobileCenter resetSharedInstance];
  [self.settingsMock setObject:[NSNumber numberWithBool:NO] forKey:kMSMobileCenterIsEnabledKey];
  [self.settingsMock setObject:[NSNumber numberWithBool:NO] forKey:self.abstractService.isEnabledKey];
  [MSMobileCenter start:MS_UUID_STRING withServices:@[[MSServiceAbstractImplementation class]]];

  // When
  [[MSServiceAbstractImplementation class] setEnabled:YES];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isFalse());
}

- (void)testDisableServiceOnCoreEnabled {

  // If
  [MSMobileCenter resetSharedInstance];
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:kMSMobileCenterIsEnabledKey];
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:self.abstractService.isEnabledKey];
  [MSMobileCenter start:MS_UUID_STRING withServices:@[[MSServiceAbstractImplementation class]]];

  // When
  [[MSServiceAbstractImplementation class] setEnabled:NO];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isFalse());
}

- (void)testEnableServiceOnCoreEnabled {

  // If
  [MSMobileCenter resetSharedInstance];
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:kMSMobileCenterIsEnabledKey];
  [self.settingsMock setObject:[NSNumber numberWithBool:NO] forKey:self.abstractService.isEnabledKey];
  [MSMobileCenter start:MS_UUID_STRING withServices:@[[MSServiceAbstractImplementation class]]];

  // When
  [[MSServiceAbstractImplementation class] setEnabled:YES];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isTrue());
}

- (void)testReenableCoreOnServiceDisabled {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:kMSMobileCenterIsEnabledKey];
  [self.settingsMock setObject:[NSNumber numberWithBool:NO] forKey:self.abstractService.isEnabledKey];
  [MSMobileCenter start:MS_UUID_STRING withServices:@[[MSServiceAbstractImplementation class]]];

  // When
  [MSMobileCenter setEnabled:YES];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isTrue());
}

- (void)testReenableCoreOnServiceEnabled {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:kMSMobileCenterIsEnabledKey];
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:self.abstractService.isEnabledKey];
  [MSMobileCenter start:MS_UUID_STRING withServices:@[[MSServiceAbstractImplementation class]]];

  // When
  [MSMobileCenter setEnabled:YES];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isTrue());
}

- (void)testLogDeletedOnDisabled {

  /**
   *  If
   */
  __block MSPriority priority;
  __block BOOL deleteLogs;
  __block BOOL forwardedEnabled;
  id <MSLogManager> logManagerMock = OCMClassMock([MSLogManagerDefault class]);
  OCMStub([logManagerMock setEnabled:NO andDeleteDataOnDisabled:YES forPriority:self.abstractService.priority])
          .andDo(^(NSInvocation *invocation) {
              [invocation getArgument:&priority atIndex:4];
              [invocation getArgument:&deleteLogs atIndex:3];
              [invocation getArgument:&forwardedEnabled atIndex:2];
          });
  self.abstractService.logManager = logManagerMock;
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:self.abstractService.isEnabledKey];

  /**
   *  When
   */
  [self.abstractService setEnabled:NO];

  /**
   *  Then
   */

  // Check that log deletion has been triggered.
  OCMVerify([logManagerMock setEnabled:NO andDeleteDataOnDisabled:YES forPriority:self.abstractService.priority]);

  // Priority from the service must match priority used to delete logs.
  assertThatBool((self.abstractService.priority == priority), isTrue());

  // Must request for deletion.
  assertThatBool(deleteLogs, isTrue());

  // Must request for disabling.
  assertThatBool(forwardedEnabled, isFalse());
}

- (void)testEnableLogManagerOnstartWithLogManager {

  // If
  id <MSLogManager> logManagerMock = OCMClassMock([MSLogManagerDefault class]);
  self.abstractService.logManager = logManagerMock;

  // When
  [self.abstractService startWithLogManager:logManagerMock appSecret:@"TestAppSecret"];

  // Then
  OCMVerify([logManagerMock setEnabled:YES andDeleteDataOnDisabled:YES forPriority:self.abstractService.priority]);
}

- (void)testInitializationPriorityCorrect {
  XCTAssertTrue([self.abstractService initializationPriority] == MSInitializationPriorityDefault);
}

@end
