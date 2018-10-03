#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSAppCenterPrivate.h"
#import "MSChannelGroupDefault.h"
#import "MSChannelUnitConfiguration.h"
#import "MSConstants+Internal.h"
#import "MSMockUserDefaults.h"
#import "MSServiceAbstractProtected.h"
#import "MSTestFrameworks.h"

@interface MSServiceAbstractImplementation : MSServiceAbstract <MSServiceInternal>

@end

@implementation MSServiceAbstractImplementation

@synthesize channelUnitConfiguration = _channelUnitConfiguration;

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
    _channelUnitConfiguration = [[MSChannelUnitConfiguration alloc] initWithGroupId:[self groupId]
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

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup appSecret:(NSString *)appSecret {
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:nil fromApplication:YES];
}

- (MSInitializationPriority)initializationPriority {
  return MSInitializationPriorityDefault;
}

+ (NSString *)logTag {
  return @"MSServiceAbstractTest";
}

- (NSString *)groupId {
  return @"groupId";
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
  self.abstractService = [MSServiceAbstractImplementation new];
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

  // If
  BOOL expected = NO;

  // When
  [self.abstractService setEnabled:expected];

  // Then
  assertThat([NSNumber numberWithBool:self.abstractService.isEnabled], is([NSNumber numberWithBool:expected]));

  // Also check that the sut did access the persistence.
  OCMVerify([self.settingsMock setObject:OCMOCK_ANY forKey:OCMOCK_ANY]);
}

- (void)testIsEnabledFromPersistence {

  // If
  NSNumber *expected = @NO;
  [self.settingsMock setObject:expected forKey:self.abstractService.isEnabledKey];

  // When
  BOOL isEnabled = [self.abstractService isEnabled];

  // Then
  assertThat(@(isEnabled), is(expected));

  // Also check that the sut did access the persistence.
  OCMVerify([self.settingsMock objectForKey:OCMOCK_ANY]);
}

- (void)testCanBeUsed {
  [MSAppCenter resetSharedInstance];

  assertThatBool([[MSServiceAbstractImplementation sharedInstance] canBeUsed], isFalse());

  [MSAppCenter start:MS_UUID_STRING withServices:@[ [MSServiceAbstractImplementation class] ]];

  assertThatBool([[MSServiceAbstractImplementation sharedInstance] canBeUsed], isTrue());
}

- (void)testEnableServiceOnCoreDisabled {
  OCMStub([self.settingsMock objectForKey:[OCMArg isEqual:@"MSAppCenterIsEnabled"]]).andReturn([NSNumber numberWithBool:NO]);

  // If
  [MSAppCenter resetSharedInstance];
  [self.settingsMock setObject:@NO forKey:kMSAppCenterIsEnabledKey];
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];
  [MSAppCenter start:MS_UUID_STRING withServices:@[ [MSServiceAbstractImplementation class] ]];

  // When
  [[MSServiceAbstractImplementation class] setEnabled:YES];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isFalse());
}

- (void)testDisableServiceOnCoreEnabled {

  // If
  [MSAppCenter resetSharedInstance];
  [self.settingsMock setObject:@YES forKey:kMSAppCenterIsEnabledKey];
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];
  [MSAppCenter start:MS_UUID_STRING withServices:@[ [MSServiceAbstractImplementation class] ]];

  // When
  [[MSServiceAbstractImplementation class] setEnabled:NO];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isFalse());
}

- (void)testEnableServiceOnCoreEnabled {

  // If
  [MSAppCenter resetSharedInstance];
  [self.settingsMock setObject:@YES forKey:kMSAppCenterIsEnabledKey];
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];
  [MSAppCenter start:MS_UUID_STRING withServices:@[ [MSServiceAbstractImplementation class] ]];

  // When
  [[MSServiceAbstractImplementation class] setEnabled:YES];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isTrue());
}

- (void)testReenableCoreOnServiceDisabled {

  // If
  [self.settingsMock setObject:@YES forKey:kMSAppCenterIsEnabledKey];
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];
  [MSAppCenter start:MS_UUID_STRING withServices:@[ [MSServiceAbstractImplementation class] ]];

  // When
  [MSAppCenter setEnabled:YES];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isTrue());
}

- (void)testReenableCoreOnServiceEnabled {

  // If
  [self.settingsMock setObject:@YES forKey:kMSAppCenterIsEnabledKey];
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];
  [MSAppCenter start:MS_UUID_STRING withServices:@[ [MSServiceAbstractImplementation class] ]];

  // When
  [MSAppCenter setEnabled:YES];

  // Then
  assertThatBool([[MSServiceAbstractImplementation class] isEnabled], isTrue());
}

- (void)testLogDeletedOnDisabled {

  // If
  id channelGroup = OCMClassMock([MSChannelGroupDefault class]);
  id channelUnit = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelGroup new]).andReturn(channelGroup);
  OCMStub([channelGroup addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnit);
  OCMExpect([channelUnit setEnabled:NO andDeleteDataOnDisabled:YES]);
  self.abstractService.channelGroup = channelGroup;
  self.abstractService.channelUnit = channelUnit;
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:NO];

  // Then

  // Check that log deletion has been triggered.
  OCMVerify([channelUnit setEnabled:NO andDeleteDataOnDisabled:YES]);

  // GroupId from the service must match the groupId used to delete logs.
  XCTAssertTrue(self.abstractService.channelUnitConfiguration.groupId == self.abstractService.groupId);

  // Clear
  [channelGroup stopMocking];
}

- (void)testEnableChannelUnitOnStartWithChannelGroup {

  // If
  id<MSChannelGroupProtocol> channelGroup = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  self.abstractService.channelGroup = channelGroup;

  // When
  [self.abstractService startWithChannelGroup:channelGroup appSecret:@"TestAppSecret"];

  // Then
  OCMVerify([self.abstractService.channelUnit setEnabled:YES andDeleteDataOnDisabled:YES]);
}

- (void)testInitializationPriorityCorrect {
  XCTAssertTrue([self.abstractService initializationPriority] == MSInitializationPriorityDefault);
}

- (void)testAppSecretRequiredByDefault {
  XCTAssertTrue([self.abstractService isAppSecretRequired]);
}

@end
