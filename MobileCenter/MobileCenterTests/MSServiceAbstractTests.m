#import "MSConstants+Internal.h"
#import "MSLogManager.h"
#import "MSLogManagerDefault.h"
#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"
#import "MSMobileCenterPrivate.h"
#import "MSMockUserDefaults.h"
#import "MSServiceAbstractPrivate.h"
#import "MSServiceAbstractProtected.h"
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@interface MSServiceAbstractImplementation : MSServiceAbstract <MSServiceInternal>

@end

@implementation MSServiceAbstractImplementation

@synthesize channelConfiguration = _channelConfiguration;

+ (instancetype)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init {
  if ((self = [super init])) {
    _channelConfiguration = [[MSChannelConfiguration alloc] initWithGroupId:[self groupId]
                                                                   priority:MSPriorityDefault
                                                              flushInterval:3.0
                                                             batchSizeLimit:50
                                                        pendingBatchesLimit:3];
  }
  return self;
}

+ (NSString *)serviceName {
  return @"Service";
}

- (void)startWithLogManager:(id<MSLogManager>)logManager appSecret:(NSString *)appSecret {
  [super startWithLogManager:logManager appSecret:appSecret];
}

- (NSString *)groupId {
  return @"MSServiceAbstractImplementation";
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
  self.settingsMock = [MSMockUserDefaults new];

  // System Under Test.
  self.abstractService = [[MSServiceAbstractImplementation alloc] initWithStorage:self.settingsMock];
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
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:NO];

  // Then
  assertThatBool([self.abstractService isEnabled], isFalse());
}

- (void)testEnableService {

  // If
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:YES];

  // Then
  assertThatBool([self.abstractService isEnabled], isTrue());
}

- (void)testDisableServiceOnServiceDisabled {

  // If
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:NO];

  // Then
  assertThatBool([self.abstractService isEnabled], isFalse());
}

- (void)testEnableServiceOnServiceEnabled {

  // If
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:YES];

  // Then
  assertThatBool([self.abstractService isEnabled], isTrue());
}

- (void)testIsEnabledToPersistence {

  /**
   *  If
   */
  BOOL expected = NO;

  /**
   *  When
   */
  [self.abstractService setEnabled:expected];

  /**
   *  Then
   */
  assertThat([NSNumber numberWithBool:self.abstractService.isEnabled], is([NSNumber numberWithBool:expected]));

  // Also check that the sut did access the persistence.
  OCMVerify([self.settingsMock setObject:[OCMArg any] forKey:[OCMArg any]]);
}

- (void)testIsEnabledFromPersistence {

  /**
   *  If
   */
  NSNumber *expected = @NO;
  [self.settingsMock setObject:expected forKey:self.abstractService.isEnabledKey];

  /**
   *  When
   */
  BOOL isEnabled = [self.abstractService isEnabled];

  /**
   *  Then
   */
  assertThat(@(isEnabled), is(expected));

  // Also check that the sut did access the persistence.
  OCMVerify([self.settingsMock objectForKey:[OCMArg any]]);
}

- (void)testCanBeUsed {
  [MSMobileCenter resetSharedInstance];

  assertThatBool([[MSServiceAbstractImplementation sharedInstance] canBeUsed], isFalse());

  [MSMobileCenter start:MS_UUID_STRING withServices:@[ [MSServiceAbstractImplementation class] ]];

  assertThatBool([[MSServiceAbstractImplementation sharedInstance] canBeUsed], isTrue());
}

- (void)testEnableServiceOnCoreDisabled {
  OCMStub([self.settingsMock objectForKey:[OCMArg isEqual:@"MSMobileCenterIsEnabled"]])
      .andReturn([NSNumber numberWithBool:NO]);

  // If
  [MSMobileCenter resetSharedInstance];
  [self.settingsMock setObject:@NO forKey:kMSMobileCenterIsEnabledKey];
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];
  [MSMobileCenter start:MS_UUID_STRING withServices:@[ [MSServiceAbstractImplementation class] ]];

  // When
  [[MSServiceAbstractImplementation class] setEnabled:YES];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isFalse());
}

- (void)testDisableServiceOnCoreEnabled {

  // If
  [MSMobileCenter resetSharedInstance];
  [self.settingsMock setObject:@YES forKey:kMSMobileCenterIsEnabledKey];
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];
  [MSMobileCenter start:MS_UUID_STRING withServices:@[ [MSServiceAbstractImplementation class] ]];

  // When
  [[MSServiceAbstractImplementation class] setEnabled:NO];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isFalse());
}

- (void)testEnableServiceOnCoreEnabled {

  // If
  [MSMobileCenter resetSharedInstance];
  [self.settingsMock setObject:@YES forKey:kMSMobileCenterIsEnabledKey];
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];
  [MSMobileCenter start:MS_UUID_STRING withServices:@[ [MSServiceAbstractImplementation class] ]];

  // When
  [[MSServiceAbstractImplementation class] setEnabled:YES];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isTrue());
}

- (void)testReenableCoreOnServiceDisabled {

  // If
  [self.settingsMock setObject:@YES forKey:kMSMobileCenterIsEnabledKey];
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];
  [MSMobileCenter start:MS_UUID_STRING withServices:@[ [MSServiceAbstractImplementation class] ]];

  // When
  [MSMobileCenter setEnabled:YES];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isTrue());
}

- (void)testReenableCoreOnServiceEnabled {

  // If
  [self.settingsMock setObject:@YES forKey:kMSMobileCenterIsEnabledKey];
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];
  [MSMobileCenter start:MS_UUID_STRING withServices:@[ [MSServiceAbstractImplementation class] ]];

  // When
  [MSMobileCenter setEnabled:YES];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isTrue());
}

- (void)testLogDeletedOnDisabled {

  /**
   *  If
   */
  __block NSString *groupId;
  __block BOOL deleteLogs;
  __block BOOL forwardedEnabled;
  id<MSLogManager> logManagerMock = OCMClassMock([MSLogManagerDefault class]);
  OCMStub([logManagerMock setEnabled:NO andDeleteDataOnDisabled:YES forGroupId:self.abstractService.groupId])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&groupId atIndex:4];
        [invocation getArgument:&deleteLogs atIndex:3];
        [invocation getArgument:&forwardedEnabled atIndex:2];
      });
  self.abstractService.logManager = logManagerMock;
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];

  /**
   *  When
   */
  [self.abstractService setEnabled:NO];

  /**
   *  Then
   */

  // Check that log deletion has been triggered.
  OCMVerify([logManagerMock setEnabled:NO andDeleteDataOnDisabled:YES forGroupId:self.abstractService.groupId]);

  // GroupId from the service must match the groupId used to delete logs.
  XCTAssertTrue(self.abstractService.groupId == groupId);

  // Must request for deletion.
  XCTAssertTrue(deleteLogs);

  // Must request for disabling.
  XCTAssertFalse(forwardedEnabled);
}

- (void)testEnableLogManagerOnStartWithLogManager {

  // If
  id<MSLogManager> logManagerMock = OCMClassMock([MSLogManagerDefault class]);
  self.abstractService.logManager = logManagerMock;

  // When
  [self.abstractService startWithLogManager:logManagerMock appSecret:@"TestAppSecret"];

  // Then
  OCMVerify([logManagerMock setEnabled:YES andDeleteDataOnDisabled:YES forGroupId:self.abstractService.groupId]);
}

- (void)testInitializationPriorityCorrect {
  XCTAssertTrue([self.abstractService initializationPriority] == MSInitializationPriorityDefault);
}

@end
