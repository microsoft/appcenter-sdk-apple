#include <Foundation/Foundation.h>
#if !TARGET_OS_TV
#import "MSCustomProperties.h"
#import "MSCustomPropertiesLog.h"
#endif
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSAppCenterPrivate.h"
#import "MSChannelUnitDefault.h"
#import "MSChannelGroupDefault.h"
#import "MSHttpSenderPrivate.h"
#import "MSMockService.h"
#import "MSMockSecondService.h"
#import "MSMockUserDefaults.h"
#import "MSStartServiceLog.h"
#import "MSTestFrameworks.h"

static NSString *const kMSInstallIdStringExample = @"F18499DA-5C3D-4F05-B4E8-D8C9C06A6F09";

// NSUUID can return this nullified InstallId while creating a UUID from a nil string, we want to avoid this.
static NSString *const kMSNullifiedInstallIdString = @"00000000-0000-0000-0000-000000000000";

@interface MSAppCenterTest : XCTestCase

@property(nonatomic) MSAppCenter *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) NSString *installId;

@end

@implementation MSAppCenterTest

- (void)setUp {
  [super setUp];
  [MSAppCenter resetSharedInstance];

  // System Under Test.
  self.sut = [[MSAppCenter alloc] init];

  self.settingsMock = [MSMockUserDefaults new];
}

- (void)tearDown {
  [self.settingsMock stopMocking];
  [super tearDown];
}

#pragma mark - install Id

- (void)testGetInstallIdFromEmptyStorage {

  // If
  // InstallId is removed from the storage.
  [self.settingsMock removeObjectForKey:kMSInstallIdKey];

  // When
  NSUUID *installId = self.sut.installId;
  NSString *installIdString = [installId UUIDString];

  // Then
  assertThat(installId, notNilValue());
  assertThat(installIdString, notNilValue());
  assertThatInteger([installIdString length], greaterThan(@(0)));
  assertThat(installIdString, isNot(kMSNullifiedInstallIdString));
}

- (void)testStartWithAppSecretAndNoTransmissionToken {
  
  // When
  [MSAppCenter start:MS_UUID_STRING withServices:@[MSMockService.class]];
  
  // Then
  XCTAssertNil([[MSAppCenter sharedInstance] defaultTransmissionTargetToken]);
  XCTAssertNotNil([[MSAppCenter sharedInstance] appSecret]);
}

- (void)testStartWithAppSecretAndTransmissionToken {
  
  // If
  NSString *secret = MS_UUID_STRING;
  NSString *transmissionTargetKey = @"target=";
  NSString *transmissionTargetString = @"transmissionTargetToken";
  NSString *appSecret = [NSString stringWithFormat:@"%@;%@%@", secret, transmissionTargetKey, transmissionTargetString];
  
  // When
  [MSAppCenter start:appSecret withServices:@[MSMockService.class]];
  
  // Then
  XCTAssertNotNil([[MSAppCenter sharedInstance] appSecret]);
  XCTAssertNotNil([[MSAppCenter sharedInstance] defaultTransmissionTargetToken]);
  XCTAssertTrue([secret isEqualToString:[[MSAppCenter sharedInstance] appSecret]]);
  XCTAssertTrue([transmissionTargetString isEqualToString:[[MSAppCenter sharedInstance] defaultTransmissionTargetToken]]);
}

- (void)testGetInstallIdFromStorage {

  // If
  // Expected installId is added to the storage.
  [self.settingsMock setObject:kMSInstallIdStringExample forKey:kMSInstallIdKey];

  // When
  NSUUID *installId = self.sut.installId;

  // Then
  assertThat(installId, is(MS_UUID_FROM_STRING(kMSInstallIdStringExample)));
  assertThat([installId UUIDString], is(kMSInstallIdStringExample));
}

- (void)testGetInstallIdFromBadStorage {

  // If
  // Unexpected installId is added to the storage.
  [self.settingsMock setObject:MS_UUID_FROM_STRING(@"42") forKey:kMSInstallIdKey];

  // When
  NSUUID *installId = self.sut.installId;
  NSString *installIdString = [installId UUIDString];

  // Then
  assertThat(installId, notNilValue());
  assertThat(installIdString, notNilValue());
  assertThatInteger([installIdString length], greaterThan(@(0)));
  assertThat(installIdString, isNot(kMSNullifiedInstallIdString));
  assertThat([installId UUIDString], isNot(@"42"));
}

- (void)testGetInstallIdTwice {

  // If
  // InstallId is removed from the storage.
  [self.settingsMock removeObjectForKey:kMSInstallIdKey];

  // When
  NSUUID *installId1 = self.sut.installId;
  NSString *installId1String = [installId1 UUIDString];

  // Then
  assertThat(installId1, notNilValue());
  assertThat(installId1String, notNilValue());
  assertThatInteger([installId1String length], greaterThan(@(0)));
  assertThat(installId1String, isNot(kMSNullifiedInstallIdString));

  // When
  // Second pick
  NSUUID *installId2 = self.sut.installId;

  // Then
  assertThat(installId1, is(installId2));
  assertThat([installId1 UUIDString], is([installId2 UUIDString]));
}

- (void)testInstallIdPersistency {

  // If
  // InstallId is removed from the storage.
  [self.settingsMock removeObjectForKey:kMSInstallIdKey];

  // When
  NSUUID *installId1 = self.sut.installId;
  self.sut = [[MSAppCenter alloc] init];
  NSUUID *installId2 = self.sut.installId;

  // Then
  assertThat(installId1, is(installId2));
  assertThat([installId1 UUIDString], is([installId2 UUIDString]));
}

- (void)testSetEnabled {
  
  // If
  [MSAppCenter start:MS_UUID_STRING withServices:@[MSMockService.class]];
  
  // When
  [self.settingsMock setObject:@NO forKey:kMSAppCenterIsEnabledKey];
  
  // Then
  XCTAssertFalse([MSAppCenter isEnabled]);
  
  // When
  [self.settingsMock setObject:@YES forKey:kMSAppCenterIsEnabledKey];
  
  // Then
  XCTAssertTrue([MSAppCenter isEnabled]);
  
  // When
  [MSAppCenter setEnabled:NO];
  
  // Then
  XCTAssertFalse([MSAppCenter isEnabled]);
  XCTAssertFalse([MSMockService isEnabled]);
  XCTAssertFalse(((NSNumber *)[self.settingsMock objectForKey:kMSAppCenterIsEnabledKey]).boolValue);
  
  // When
  [MSAppCenter setEnabled:YES];
  
  // Then
  XCTAssertTrue([MSAppCenter isEnabled]);
  XCTAssertTrue([MSMockService isEnabled]);
  XCTAssertTrue(((NSNumber *)[self.settingsMock objectForKey:kMSAppCenterIsEnabledKey]).boolValue);
}

- (void)testSetLogUrl {
  NSString *fakeUrl = @"http://testUrl:1234";
  [MSAppCenter setLogUrl:fakeUrl];
  [MSAppCenter start:MS_UUID_STRING withServices:nil];
  XCTAssertTrue([[[MSAppCenter sharedInstance] logUrl] isEqualToString:fakeUrl]);
}

- (void)testDefaultLogUrl {
  [MSAppCenter start:MS_UUID_STRING withServices:nil];
  XCTAssertTrue([[[MSAppCenter sharedInstance] logUrl] isEqualToString:@"https://in.appcenter.ms"]);
}

- (void)testSdkVersion {
  NSString *version = [NSString stringWithUTF8String:APP_CENTER_C_VERSION];
  XCTAssertTrue([[MSAppCenter sdkVersion] isEqualToString:version]);
}

- (void)testDisableServicesWithEnvironmentVariable {
  const char* disableVariableCstr = [kMSDisableVariable UTF8String];
  const char* disableAllCstr = [kMSDisableAll UTF8String];
  
  // If
  setenv(disableVariableCstr, disableAllCstr, 1);
  [[MSMockService sharedInstance] setStarted:NO];
  [[MSMockSecondService sharedInstance] setStarted:NO];

  // When
  [MSAppCenter start:@"AppSecret" withServices:@[MSMockService.class, MSMockSecondService.class]];

  // Then
  XCTAssertFalse([[MSMockService sharedInstance] started]);
  XCTAssertFalse([[MSMockSecondService sharedInstance] started]);

  // If
  setenv(disableVariableCstr, [[MSMockService serviceName] UTF8String], 1);
  [[MSMockService sharedInstance] setStarted:NO];
  [[MSMockSecondService sharedInstance] setStarted:NO];
  [MSAppCenter resetSharedInstance];

  // When
  [MSAppCenter start:@"AppSecret" withServices:@[MSMockService.class, MSMockSecondService.class]];

  // Then
  XCTAssertFalse([[MSMockService sharedInstance] started]);
  XCTAssertTrue([[MSMockSecondService sharedInstance] started]);
  
  // If
  NSString* disableList = [NSString stringWithFormat:@"%@,SomeService,%@", [MSMockService serviceName], [MSMockSecondService serviceName]];
  setenv(disableVariableCstr, [disableList UTF8String], 1);
  [[MSMockService sharedInstance] setStarted:NO];
  [[MSMockSecondService sharedInstance] setStarted:NO];
  [MSAppCenter resetSharedInstance];

  // When
  [MSAppCenter start:@"AppSecret" withServices:@[MSMockService.class, MSMockSecondService.class]];

  // Then
  XCTAssertFalse([[MSMockService sharedInstance] started]);
  XCTAssertFalse([[MSMockSecondService sharedInstance] started]);

  // Repeat previous test but with some whitespace.
  // If
  disableList = [NSString stringWithFormat:@" %@ , SomeService,%@ ", [MSMockService serviceName], [MSMockSecondService serviceName]];
  setenv(disableVariableCstr, [disableList UTF8String], 1);
  [[MSMockService sharedInstance] setStarted:NO];
  [[MSMockSecondService sharedInstance] setStarted:NO];
  [MSAppCenter resetSharedInstance];
  
  // When
  [MSAppCenter start:@"AppSecret" withServices:@[MSMockService.class, MSMockSecondService.class]];
  
  // Then
  XCTAssertFalse([[MSMockService sharedInstance] started]);
  XCTAssertFalse([[MSMockSecondService sharedInstance] started]);
  
  // Special tear down.
  setenv(disableVariableCstr, "", 1);
}
      
#if !TARGET_OS_TV
- (void)testSetCustomProperties {

  // If
  [MSAppCenter start:MS_UUID_STRING withServices:nil];
  id channelUnit = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]]])
      .andDo(nil);
  [MSAppCenter sharedInstance].channelUnit = channelUnit;

  // When
  MSCustomProperties *customProperties = [MSCustomProperties new];
  [customProperties setString:@"test" forKey:@"test"];
  [MSAppCenter setCustomProperties:customProperties];

  // Then
  OCMVerify([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]]]);

  // When
  // Not allow processLog more
  OCMReject([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]]]);
  [MSAppCenter setCustomProperties:nil];
  [MSAppCenter setCustomProperties:[MSCustomProperties new]];

  // Then
  OCMVerifyAll(channelUnit);
}
#endif

- (void)testConfigureWithAppSecret {
  [MSAppCenter configureWithAppSecret:@"App-Secret"];
  XCTAssertTrue([MSAppCenter isConfigured]);
}

- (void)testStartServiceWithInvalidValues {
  NSUInteger servicesCount = [[MSAppCenter sharedInstance] services].count;
  [MSAppCenter startService:[MSAppCenter class]];
  [MSAppCenter startService:[NSString class]];
  [MSAppCenter startService:nil];
  XCTAssertEqual(servicesCount, [[MSAppCenter sharedInstance] services].count);
}

- (void)testStartServiceWithoutAppSecret {
  [MSAppCenter startService:[MSMockService class]];
  XCTAssertEqual((uint)1, [[MSAppCenter sharedInstance] services].count);
}

- (void)testStartWithoutServices {

  // If
  id channelGroup = OCMClassMock([MSChannelGroupDefault class]);
  id channelUnit = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelGroup alloc]).andReturn(channelGroup);
  OCMStub([channelGroup initWithAppSecret:OCMOCK_ANY installId:OCMOCK_ANY logUrl:OCMOCK_ANY]).andReturn(channelGroup);
  OCMStub([channelGroup addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnit);

  // Not allow processLog.
  OCMReject([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSStartServiceLog class]]]);

  // When
  [MSAppCenter start:MS_UUID_STRING withServices:nil];

  // Then
  OCMVerifyAll(channelUnit);

  // Clear
  [channelGroup stopMocking];
}

- (void)testStartServiceLogIsSentAfterStartService {

  // If
  [MSAppCenter start:MS_UUID_STRING withServices:nil];
  id channelUnit = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSStartServiceLog class]]]).andDo(nil);
  [MSAppCenter sharedInstance].channelUnit = channelUnit;

  // When
  [MSAppCenter startService:MSMockService.class];

  // Then
  OCMVerify([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSStartServiceLog class]]]);
}

- (void)testDisabledCoreStatus {
  
  // When
  [MSAppCenter start:MS_UUID_STRING withServices:@[MSMockService.class]];
  [MSAppCenter setEnabled:NO];
  
  // Then
  MSChannelGroupDefault *channelGroup = (MSChannelGroupDefault *)[MSAppCenter sharedInstance].channelGroup;
  XCTAssertFalse(channelGroup.sender.enabled);
  XCTAssertFalse([MSMockService isEnabled]);
}

- (void)testDisabledCorePersistedStatus {
  
  // If
  [self.settingsMock setObject:@NO forKey:kMSAppCenterIsEnabledKey];
  
  // When
  [MSAppCenter start:MS_UUID_STRING withServices:@[MSMockService.class]];
 
  // Then
  MSChannelGroupDefault *channelGroup = (MSChannelGroupDefault *)[MSAppCenter sharedInstance].channelGroup;
  XCTAssertFalse(channelGroup.sender.enabled);
  XCTAssertFalse([MSMockService isEnabled]);
}

- (void)testStartServiceLogWithDisabledCore {
  
  // If
  id channelGroup = OCMClassMock([MSChannelGroupDefault class]);
  id channelUnit = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelGroup alloc]).andReturn(channelGroup);
  OCMStub([channelGroup initWithAppSecret:OCMOCK_ANY installId:OCMOCK_ANY logUrl:OCMOCK_ANY]).andReturn(channelGroup);
  OCMStub([channelGroup addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnit);
  __block NSInteger logsProcessed = 0;
  __block MSStartServiceLog *log = nil;
  OCMStub([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSStartServiceLog class]]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&log atIndex:2];
        logsProcessed++;
      });
  
  // When
  [MSAppCenter start:MS_UUID_STRING withServices:nil];
  [MSAppCenter setEnabled:NO];
  [MSAppCenter startService:MSMockService.class];
  [MSAppCenter startService:MSMockSecondService.class];
  
  // Then
  assertThatInteger(logsProcessed, equalToInteger(0));
  XCTAssertFalse([MSMockService isEnabled]);
  XCTAssertFalse([MSMockSecondService isEnabled]);
  XCTAssertNil(log);
  
  // When
  [MSAppCenter setEnabled:YES];
  
  // Then
  assertThatInteger(logsProcessed, equalToInteger(1));
  XCTAssertNotNil(log);
  NSArray *expected = @[@"MSMockService", @"MSMockSecondService"];
  XCTAssertTrue([log.services isEqual:expected]);
  
  // Clear
  [channelGroup stopMocking];
}

- (void)testSortingServicesWorks {

  // If
  id<MSServiceCommon> mockServiceMaxPrio = OCMProtocolMock(@protocol(MSServiceCommon));
  OCMStub([mockServiceMaxPrio sharedInstance]).andReturn(mockServiceMaxPrio);
  OCMStub([mockServiceMaxPrio initializationPriority]).andReturn(MSInitializationPriorityMax);

  id<MSServiceCommon> mockServiceDefaultPrio = OCMProtocolMock(@protocol(MSServiceCommon));
  OCMStub([mockServiceDefaultPrio sharedInstance]).andReturn(mockServiceDefaultPrio);
  OCMStub([mockServiceDefaultPrio initializationPriority]).andReturn(MSInitializationPriorityDefault);

  // When
  NSArray<MSServiceAbstract *> *sorted =
      [self.sut sortServices:@[ (Class)mockServiceDefaultPrio, (Class)mockServiceMaxPrio ]];

  // Then
  XCTAssertTrue([sorted[0] initializationPriority] == MSInitializationPriorityMax);
  XCTAssertTrue([sorted[1] initializationPriority] == MSInitializationPriorityDefault);
}

#if !TARGET_OS_OSX
- (void)testAppIsBackgrounded {

  // If
  id<MSChannelGroupProtocol> channelGroup = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  [self.sut configure:@"AnAppSecret"];
  self.sut.channelGroup = channelGroup;

  // When
  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification
                                                      object:self.sut];
  // Then
  OCMVerify([channelGroup suspend]);
}

- (void)testAppIsForegrounded {

  // If
  id<MSChannelGroupProtocol> channelGroup = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  [self.sut configure:@"AnAppSecret"];
  self.sut.channelGroup = channelGroup;

  // When
  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification

                                                      object:self.sut];
  // Then
  OCMVerify([channelGroup resume]);
}
#endif

@end
