// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSAppCenterPrivate.h"
#import "MSChannelGroupDefault.h"
#import "MSChannelUnitConfiguration.h"
#import "MSConstants+Internal.h"
#import "MSMockUserDefaults.h"
#import "MSSessionContextPrivate.h"
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
@property(nonatomic) id sessionContextMock;
@property(nonatomic) id channelGroupMock;
@property(nonatomic) id channelUnitMock;

/**
 * System Under test.
 */
@property(nonatomic) MSServiceAbstractImplementation *abstractService;

@end

@implementation MSServiceAbstractTest

- (void)setUp {
  [super setUp];
  [MSAppCenter resetSharedInstance];

  // Set up the mocked storage.
  self.settingsMock = [MSMockUserDefaults new];

  // Session context.
  [MSSessionContext resetSharedInstance];
  self.sessionContextMock = OCMClassMock([MSSessionContext class]);
  OCMStub([self.sessionContextMock sharedInstance]).andReturn(self.sessionContextMock);

  // Set up the mock channel.
  self.channelGroupMock = OCMClassMock([MSChannelGroupDefault class]);
  self.channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([self.channelGroupMock alloc]).andReturn(self.channelGroupMock);
  OCMStub([self.channelGroupMock initWithHttpClient:OCMOCK_ANY installId:OCMOCK_ANY logUrl:OCMOCK_ANY]).andReturn(self.channelGroupMock);
  OCMStub([self.channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(self.channelUnitMock);

  // System Under Test.
  self.abstractService = [MSServiceAbstractImplementation new];
}

- (void)tearDown {
  [self.channelGroupMock stopMocking];
  [self.settingsMock stopMocking];
  [self.sessionContextMock stopMocking];
  [MSAppCenter resetSharedInstance];
  [MSSessionContext resetSharedInstance];
  [super tearDown];
}

- (void)testIsEnabledTrueByDefault {

  // When
  BOOL isEnabled = [self.abstractService isEnabled];

  // Then
  XCTAssertTrue(isEnabled);
}

- (void)testDisableService {

  // If
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:NO];

  // Then
  XCTAssertFalse([self.abstractService isEnabled]);
}

- (void)testEnableService {

  // If
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:YES];

  // Then
  XCTAssertTrue([self.abstractService isEnabled]);
}

- (void)testDisableServiceOnServiceDisabled {

  // If
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:NO];

  // Then
  XCTAssertFalse([self.abstractService isEnabled]);
}

- (void)testEnableServiceOnServiceEnabled {

  // If
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:YES];

  // Then
  XCTAssertTrue([self.abstractService isEnabled]);
}

- (void)testIsEnabledToPersistence {

  // If
  BOOL expected = NO;

  // When
  [self.abstractService setEnabled:expected];

  // Then
  XCTAssertTrue(self.abstractService.isEnabled == expected);

  // Also check that the sut did access the persistence.
  XCTAssertTrue([[self.settingsMock objectForKey:self.abstractService.isEnabledKey] boolValue] == expected);
}

- (void)testIsEnabledFromPersistence {

  // If
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];

  // Then
  XCTAssertFalse([self.abstractService isEnabled]);

  // If
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];

  // Then
  XCTAssertTrue([self.abstractService isEnabled]);
}

- (void)testCanBeUsed {

  // If
  [MSAppCenter resetSharedInstance];

  // Then
  XCTAssertFalse([[MSServiceAbstractImplementation sharedInstance] canBeUsed]);

  // When
  [MSAppCenter start:MS_UUID_STRING withServices:@ [[MSServiceAbstractImplementation class]]];

  // Then
  XCTAssertTrue([[MSServiceAbstractImplementation sharedInstance] canBeUsed]);
}

- (void)testEnableServiceOnCoreDisabled {

  // If
  [MSAppCenter resetSharedInstance];
  [self.settingsMock setObject:@NO forKey:kMSAppCenterIsEnabledKey];
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];
  [MSAppCenter start:MS_UUID_STRING withServices:@ [[MSServiceAbstractImplementation class]]];

  // When
  [[MSServiceAbstractImplementation class] setEnabled:YES];

  // Then
  XCTAssertFalse([[MSServiceAbstractImplementation class] isEnabled]);
}

- (void)testDisableServiceOnCoreEnabled {

  // If
  [MSAppCenter resetSharedInstance];
  [self.settingsMock setObject:@YES forKey:kMSAppCenterIsEnabledKey];
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];
  [MSAppCenter start:MS_UUID_STRING withServices:@ [[MSServiceAbstractImplementation class]]];

  // When
  [[MSServiceAbstractImplementation class] setEnabled:NO];

  // Then
  XCTAssertFalse([[MSServiceAbstractImplementation class] isEnabled]);
}

- (void)testEnableServiceOnCoreEnabled {

  // If
  [MSAppCenter resetSharedInstance];
  [self.settingsMock setObject:@YES forKey:kMSAppCenterIsEnabledKey];
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];
  [MSAppCenter start:MS_UUID_STRING withServices:@ [[MSServiceAbstractImplementation class]]];

  // When
  [[MSServiceAbstractImplementation class] setEnabled:YES];

  // Then
  XCTAssertTrue([[MSServiceAbstractImplementation class] isEnabled]);
}

- (void)testReenableCoreOnServiceDisabled {

  // If
  [self.settingsMock setObject:@YES forKey:kMSAppCenterIsEnabledKey];
  [self.settingsMock setObject:@NO forKey:self.abstractService.isEnabledKey];
  [MSAppCenter start:MS_UUID_STRING withServices:@ [[MSServiceAbstractImplementation class]]];

  // When
  [MSAppCenter setEnabled:YES];

  // Then
  XCTAssertTrue([[MSServiceAbstractImplementation class] isEnabled]);
}

- (void)testReenableCoreOnServiceEnabled {

  // If
  [self.settingsMock setObject:@YES forKey:kMSAppCenterIsEnabledKey];
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];
  [MSAppCenter start:MS_UUID_STRING withServices:@ [[MSServiceAbstractImplementation class]]];

  // When
  [MSAppCenter setEnabled:YES];

  // Then
  XCTAssertTrue([[MSServiceAbstractImplementation class] isEnabled]);
}

- (void)testLogDeletedOnDisabled {

  // If
  self.abstractService.channelGroup = self.channelGroupMock;
  self.abstractService.channelUnit = self.channelUnitMock;
  [self.settingsMock setObject:@YES forKey:self.abstractService.isEnabledKey];

  // When
  [self.abstractService setEnabled:NO];

  // Then
  // Check that log deletion has been triggered.
  OCMVerify([self.channelUnitMock setEnabled:NO andDeleteDataOnDisabled:YES]);

  // GroupId from the service must match the groupId used to delete logs.
  XCTAssertTrue(self.abstractService.channelUnitConfiguration.groupId == self.abstractService.groupId);
}

- (void)testEnableChannelUnitOnStartWithChannelGroup {

  // When
  [self.abstractService startWithChannelGroup:self.channelGroupMock appSecret:@"TestAppSecret"];

  // Then
  OCMVerify([self.channelUnitMock setEnabled:YES andDeleteDataOnDisabled:YES]);
}

- (void)testInitializationPriorityCorrect {
  XCTAssertTrue([self.abstractService initializationPriority] == MSInitializationPriorityDefault);
}

- (void)testAppSecretRequiredByDefault {
  XCTAssertTrue([self.abstractService isAppSecretRequired]);
}

@end
