#include <Foundation/Foundation.h>

#if !TARGET_OS_TV
#import "MSCustomProperties.h"
#import "MSCustomPropertiesLog.h"
#endif

#import "MSAppCenter.h"
#import "MSAppCenterIngestion.h"
#import "MSAppCenterInternal.h"
#import "MSAppCenterPrivate.h"
#import "MSChannelGroupDefault.h"
#import "MSDeviceTrackerPrivate.h"
#import "MSHttpIngestionPrivate.h"
#import "MSMockSecondService.h"
#import "MSMockService.h"
#import "MSMockUserDefaults.h"
#import "MSOneCollectorChannelDelegate.h"
#import "MSSessionContextPrivate.h"
#import "MSStartServiceLog.h"
#import "MSTestFrameworks.h"
#import "MSUserIdContextPrivate.h"

static NSString *const kMSInstallIdStringExample = @"F18499DA-5C3D-4F05-B4E8-D8C9C06A6F09";

// NSUUID can return this nullified InstallId while creating a UUID from a nil string, we want to avoid this.
static NSString *const kMSNullifiedInstallIdString = @"00000000-0000-0000-0000-000000000000";

@interface MSAppCenterTest : XCTestCase

@property(nonatomic) MSAppCenter *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) NSString *installId;
@property(nonatomic) id deviceTrackerMock;
@property(nonatomic) id sessionContextMock;

@end

@implementation MSAppCenterTest

- (void)setUp {
  [super setUp];
  [MSAppCenter resetSharedInstance];
  [MSUserIdContext resetSharedInstance];

  // System Under Test.
  self.sut = [[MSAppCenter alloc] init];

  self.settingsMock = [MSMockUserDefaults new];
  [MSDeviceTracker resetSharedInstance];
  self.deviceTrackerMock = OCMClassMock([MSDeviceTracker class]);
  OCMStub([self.deviceTrackerMock sharedInstance]).andReturn(self.deviceTrackerMock);
  [MSSessionContext resetSharedInstance];
  self.sessionContextMock = OCMClassMock([MSSessionContext class]);
  OCMStub([self.sessionContextMock sharedInstance]).andReturn(self.sessionContextMock);
}

- (void)tearDown {
  [self.settingsMock stopMocking];
  [MSMockService resetSharedInstance];
  [MSMockSecondService resetSharedInstance];
  [self.deviceTrackerMock stopMocking];
  [self.sessionContextMock stopMocking];
  [MSDeviceTracker resetSharedInstance];
  [MSSessionContext resetSharedInstance];
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

- (void)testStartWithAppSecretOnly {

  // When
  NSString *appSecret = MS_UUID_STRING;
  [MSAppCenter start:appSecret withServices:@[ MSMockService.class, MSMockSecondService.class ]];

  // Then
  XCTAssertNil([[MSAppCenter sharedInstance] defaultTransmissionTargetToken]);
  XCTAssertTrue([[[MSAppCenter sharedInstance] appSecret] isEqualToString:appSecret]);
  XCTAssertTrue([MSMockService sharedInstance].started);
  XCTAssertTrue([MSMockSecondService sharedInstance].started);
}

- (void)testStartWithAppSecretAndTransmissionToken {

  // If
  NSString *appSecret = MS_UUID_STRING;
  NSString *transmissionTargetKey = @"target=";
  NSString *transmissionTargetString = @"transmissionTargetToken";
  NSString *secret = [NSString stringWithFormat:@"%@;%@%@", appSecret, transmissionTargetKey, transmissionTargetString];

  // When
  [MSAppCenter start:secret withServices:@[ MSMockService.class ]];
  [MSAppCenter startService:MSMockSecondService.class];

  // Then
  XCTAssertTrue([[[MSAppCenter sharedInstance] appSecret] isEqualToString:appSecret]);
  XCTAssertTrue([[[MSAppCenter sharedInstance] defaultTransmissionTargetToken] isEqualToString:transmissionTargetString]);
  XCTAssertTrue([MSMockService sharedInstance].started);
  XCTAssertTrue([[[MSMockService sharedInstance] defaultTransmissionTargetToken] isEqualToString:transmissionTargetString]);
  XCTAssertTrue([MSMockSecondService sharedInstance].started);
  XCTAssertTrue([[[MSMockSecondService sharedInstance] defaultTransmissionTargetToken] isEqualToString:transmissionTargetString]);
}

- (void)testStartWithNoAppSecret {

  // If
  NSArray *services = @[ MSMockService.class, MSMockSecondService.class ];

  // When
  [MSAppCenter startWithServices:services];

  // Then
  XCTAssertNil([[MSAppCenter sharedInstance] appSecret]);
  XCTAssertFalse([MSMockService sharedInstance].started);
  XCTAssertTrue([MSMockSecondService sharedInstance].started);
}

- (void)testStartWithTransmissionTokenOnly {

  // If
  NSString *transmissionTargetKey = @"target=";
  NSString *transmissionTargetString = @"transmissionTargetToken";
  NSString *secret = [NSString stringWithFormat:@"%@%@", transmissionTargetKey, transmissionTargetString];

  // When
  [MSAppCenter start:secret withServices:@[ MSMockService.class, MSMockSecondService.class ]];

  // Then
  XCTAssertNil([[MSAppCenter sharedInstance] appSecret]);
  XCTAssertTrue([[[MSAppCenter sharedInstance] defaultTransmissionTargetToken] isEqualToString:transmissionTargetString]);
  XCTAssertFalse([MSMockService sharedInstance].started);
  XCTAssertTrue([MSMockSecondService sharedInstance].started);
}

- (void)testStartSameServiceFromLibraryAndThenApplication {

  // When
  [MSAppCenter startFromLibraryWithServices:@[ MSMockSecondService.class ]];

  // Then
  XCTAssertNil([[MSAppCenter sharedInstance] appSecret]);
  XCTAssertFalse([MSAppCenter isConfigured]);
  XCTAssertNil([MSMockSecondService sharedInstance].appSecret);
  XCTAssertTrue([MSMockSecondService sharedInstance].started);

  // When
  [MSAppCenter start:MS_UUID_STRING withServices:@[ MSMockSecondService.class ]];

  // Then
  XCTAssertNotNil([[MSAppCenter sharedInstance] appSecret]);
  XCTAssertTrue([MSAppCenter isConfigured]);
  XCTAssertNotNil([MSMockSecondService sharedInstance].appSecret);
  XCTAssertTrue([MSMockSecondService sharedInstance].started);
}

- (void)testStartServicesFromLibraryAndThenApplication {

  // When
  [MSAppCenter startFromLibraryWithServices:@[ MSMockSecondService.class ]];
  [MSAppCenter start:MS_UUID_STRING withServices:@[ MSMockService.class ]];

  // Then
  XCTAssertNotNil([[MSAppCenter sharedInstance] appSecret]);
  XCTAssertNotNil([MSMockService sharedInstance].appSecret);
  XCTAssertNil([MSMockSecondService sharedInstance].appSecret);
  XCTAssertTrue([MSMockService sharedInstance].started);
  XCTAssertTrue([MSMockSecondService sharedInstance].started);
}

- (void)testStartSameServiceFromApplicationAndThenLibrary {

  // When
  [MSAppCenter start:MS_UUID_STRING withServices:@[ MSMockSecondService.class ]];

  // Then
  XCTAssertNotNil([[MSAppCenter sharedInstance] appSecret]);
  XCTAssertTrue([MSAppCenter isConfigured]);
  XCTAssertNotNil([MSMockSecondService sharedInstance].appSecret);
  XCTAssertTrue([MSMockSecondService sharedInstance].started);

  // When
  [MSAppCenter startFromLibraryWithServices:@[ MSMockSecondService.class ]];

  // Then
  XCTAssertNotNil([[MSAppCenter sharedInstance] appSecret]);
  XCTAssertTrue([MSAppCenter isConfigured]);
  XCTAssertNotNil([MSMockSecondService sharedInstance].appSecret);
  XCTAssertTrue([MSMockSecondService sharedInstance].started);
}

- (void)testStartServicesFromApplicationAndThenLibrary {

  // When
  [MSAppCenter start:MS_UUID_STRING withServices:@[ MSMockService.class ]];
  [MSAppCenter startFromLibraryWithServices:@[ MSMockSecondService.class ]];

  // Then
  XCTAssertNotNil([[MSAppCenter sharedInstance] appSecret]);
  XCTAssertNotNil([MSMockService sharedInstance].appSecret);
  XCTAssertNil([MSMockSecondService sharedInstance].appSecret);
  XCTAssertTrue([MSMockService sharedInstance].started);
  XCTAssertTrue([MSMockSecondService sharedInstance].started);
}

- (void)testConfigureWithNoAppSecret {

  // When
  [MSAppCenter configure];

  // Then
  XCTAssertTrue([MSAppCenter isConfigured]);
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
  [MSAppCenter start:MS_UUID_STRING withServices:@[ MSMockService.class ]];

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
  OCMVerify([self.deviceTrackerMock clearDevices]);
  OCMVerify([self.sessionContextMock clearSessionHistoryAndKeepCurrentSession:NO]);

  // When
  [MSAppCenter setEnabled:YES];

  // Then
  XCTAssertTrue([MSAppCenter isEnabled]);
  XCTAssertTrue([MSMockService isEnabled]);
  XCTAssertTrue(((NSNumber *)[self.settingsMock objectForKey:kMSAppCenterIsEnabledKey]).boolValue);
}

- (void)testClearUserIdHistoryWhenAppCenterIsDisabled {

  // If
  [MSAppCenter start:MS_UUID_STRING withServices:@[ MSMockService.class ]];
  [[MSUserIdContext sharedInstance] setUserId:@"alice"];
  [MSUserIdContext resetSharedInstance];
  [[MSUserIdContext sharedInstance] setUserId:@"bob"];

  // Then
  XCTAssertEqual(2, [[MSUserIdContext sharedInstance].userIdHistory count]);

  // When
  [MSAppCenter setEnabled:NO];

  // Then
  XCTAssertFalse([MSAppCenter isEnabled]);

  // Clearing history won't remove the most recent userId.
  XCTAssertEqual(1, [[MSUserIdContext sharedInstance].userIdHistory count]);
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
  const char *disableVariableCstr = [kMSDisableVariable UTF8String];
  const char *disableAllCstr = [kMSDisableAll UTF8String];

  // If
  setenv(disableVariableCstr, disableAllCstr, 1);
  [[MSMockService sharedInstance] setStarted:NO];
  [[MSMockSecondService sharedInstance] setStarted:NO];

  // When
  [MSAppCenter start:@"AppSecret" withServices:@[ MSMockService.class, MSMockSecondService.class ]];

  // Then
  XCTAssertFalse([[MSMockService sharedInstance] started]);
  XCTAssertFalse([[MSMockSecondService sharedInstance] started]);

  // If
  setenv(disableVariableCstr, [[MSMockService serviceName] UTF8String], 1);
  [[MSMockService sharedInstance] setStarted:NO];
  [[MSMockSecondService sharedInstance] setStarted:NO];
  [MSAppCenter resetSharedInstance];

  // When
  [MSAppCenter start:@"AppSecret" withServices:@[ MSMockService.class, MSMockSecondService.class ]];

  // Then
  XCTAssertFalse([[MSMockService sharedInstance] started]);
  XCTAssertTrue([[MSMockSecondService sharedInstance] started]);

  // If
  NSString *disableList = [NSString stringWithFormat:@"%@,SomeService,%@", [MSMockService serviceName], [MSMockSecondService serviceName]];
  setenv(disableVariableCstr, [disableList UTF8String], 1);
  [[MSMockService sharedInstance] setStarted:NO];
  [[MSMockSecondService sharedInstance] setStarted:NO];
  [MSAppCenter resetSharedInstance];

  // When
  [MSAppCenter start:@"AppSecret" withServices:@[ MSMockService.class, MSMockSecondService.class ]];

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
  [MSAppCenter start:@"AppSecret" withServices:@[ MSMockService.class, MSMockSecondService.class ]];

  // Then
  XCTAssertFalse([[MSMockService sharedInstance] started]);
  XCTAssertFalse([[MSMockSecondService sharedInstance] started]);

  // Special tear down.
  setenv(disableVariableCstr, "", 1);
}

#if !TARGET_OS_TV

- (void)testSetCustomPropertiesWithEmptyPropertiesDoesNotEnqueueCustomPropertiesLog {

  // If
  [MSAppCenter start:MS_UUID_STRING withServices:nil];
  id channelUnit = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]] flags:MSFlagsDefault]).andDo(nil);
  [MSAppCenter sharedInstance].channelUnit = channelUnit;

  // When
  OCMReject([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]] flags:MSFlagsDefault]);
  MSCustomProperties *customProperties = [MSCustomProperties new];
  [MSAppCenter setCustomProperties:customProperties];

  // Then
  OCMVerifyAll(channelUnit);
}

- (void)testSetCustomProperties {

  // If
  [MSAppCenter start:MS_UUID_STRING withServices:nil];
  id channelUnit = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]] flags:MSFlagsDefault]).andDo(nil);
  [MSAppCenter sharedInstance].channelUnit = channelUnit;

  // When
  MSCustomProperties *customProperties = [MSCustomProperties new];
  [customProperties setString:@"test" forKey:@"test"];
  [MSAppCenter setCustomProperties:customProperties];

  // Then
  OCMVerify([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]] flags:MSFlagsDefault]);

  // When
  // Not allow processLog more
  OCMReject([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]] flags:MSFlagsDefault]);
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

- (void)testConfigureWithAppSecretAndTransmissionToken {

  // If
  NSString *appSecret = MS_UUID_STRING;
  NSString *transmissionTargetKey = @"target=";
  NSString *transmissionTargetString = @"transmissionTargetToken";
  NSString *secret = [NSString stringWithFormat:@"%@;%@%@", appSecret, transmissionTargetKey, transmissionTargetString];

  // When
  [MSAppCenter configureWithAppSecret:secret];

  // Then
  XCTAssertTrue([MSAppCenter isConfigured]);
  XCTAssertTrue([[[MSAppCenter sharedInstance] appSecret] isEqualToString:appSecret]);
  XCTAssertTrue([[[MSAppCenter sharedInstance] defaultTransmissionTargetToken] isEqualToString:transmissionTargetString]);
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
  XCTAssertEqual((uint)0, [[MSAppCenter sharedInstance] services].count);
  [MSAppCenter startService:[MSMockSecondService class]];
  XCTAssertEqual((uint)0, [[MSAppCenter sharedInstance] services].count);
}

- (void)testStartWithoutServices {

  // If
  id channelGroup = OCMClassMock([MSChannelGroupDefault class]);
  id channelUnit = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelGroup alloc]).andReturn(channelGroup);
  OCMStub([channelGroup initWithInstallId:OCMOCK_ANY logUrl:OCMOCK_ANY]).andReturn(channelGroup);
  OCMStub([channelGroup addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnit);

  // Not allow processLog.
  OCMReject([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSStartServiceLog class]] flags:MSFlagsDefault]);

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
  OCMStub([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSStartServiceLog class]] flags:MSFlagsDefault]).andDo(nil);
  [MSAppCenter sharedInstance].channelUnit = channelUnit;

  // When
  [MSAppCenter startService:MSMockService.class];

  // Then
  OCMVerify([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSStartServiceLog class]] flags:MSFlagsDefault]);
}

- (void)testDisabledCoreStatus {

  // When
  [MSAppCenter start:MS_UUID_STRING withServices:@[ MSMockService.class ]];
  [MSAppCenter setEnabled:NO];

  // Then
  MSChannelGroupDefault *channelGroup = (MSChannelGroupDefault *)[MSAppCenter sharedInstance].channelGroup;
  XCTAssertFalse(channelGroup.ingestion.enabled);
  XCTAssertFalse([MSMockService isEnabled]);
}

- (void)testDisabledCorePersistedStatus {

  // If
  [self.settingsMock setObject:@NO forKey:kMSAppCenterIsEnabledKey];

  // When
  [MSAppCenter start:MS_UUID_STRING withServices:@[ MSMockService.class ]];

  // Then
  MSChannelGroupDefault *channelGroup = (MSChannelGroupDefault *)[MSAppCenter sharedInstance].channelGroup;
  XCTAssertFalse(channelGroup.ingestion.enabled);
  XCTAssertFalse([MSMockService isEnabled]);
}

- (void)testStartServiceLogWithDisabledCore {

  // If
  id channelGroup = OCMClassMock([MSChannelGroupDefault class]);
  id channelUnit = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  OCMStub([channelGroup alloc]).andReturn(channelGroup);
  OCMStub([channelGroup initWithInstallId:OCMOCK_ANY logUrl:OCMOCK_ANY]).andReturn(channelGroup);
  OCMStub([channelGroup addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnit);
  __block NSInteger logsProcessed = 0;
  __block MSStartServiceLog *log = nil;
  OCMStub([channelUnit enqueueItem:[OCMArg isKindOfClass:[MSStartServiceLog class]] flags:MSFlagsDefault])
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
  NSArray *expected = @[ @"MSMockService", @"MSMockSecondService" ];
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
  NSArray<MSServiceAbstract *> *sorted = [self.sut sortServices:@[ (Class)mockServiceDefaultPrio, (Class)mockServiceMaxPrio ]];

  // Then
  XCTAssertTrue([sorted[0] initializationPriority] == MSInitializationPriorityMax);
  XCTAssertTrue([sorted[1] initializationPriority] == MSInitializationPriorityDefault);
}

- (void)testChannelOneCollectorDelegateSet {

  // If
  id channelGroup = OCMClassMock([MSChannelGroupDefault class]);
  OCMStub([channelGroup alloc]).andReturn(channelGroup);
  OCMStub([channelGroup initWithInstallId:OCMOCK_ANY logUrl:OCMOCK_ANY]).andReturn(channelGroup);

  // When
  [MSAppCenter start:MS_UUID_STRING withServices:nil];

  // Then
  OCMVerify([channelGroup addDelegate:[OCMArg isKindOfClass:[MSOneCollectorChannelDelegate class]]]);

  // Clear
  [channelGroup stopMocking];
}

#if !TARGET_OS_OSX
- (void)testAppIsBackgrounded {

  // If
  id<MSChannelGroupProtocol> channelGroup = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  [self.sut configureWithAppSecret:@"AppSecret" transmissionTargetToken:nil fromApplication:YES];
  self.sut.channelGroup = channelGroup;

  // When
  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:self.sut];
  // Then
  OCMVerify([channelGroup pauseWithIdentifyingObject:self.sut]);
}

- (void)testAppIsForegrounded {

  // If
  id<MSChannelGroupProtocol> channelGroup = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  [self.sut configureWithAppSecret:@"AppSecret" transmissionTargetToken:nil fromApplication:YES];
  self.sut.channelGroup = channelGroup;

  // When
  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification

                                                      object:self.sut];
  // Then
  OCMVerify([channelGroup resumeWithIdentifyingObject:self.sut]);
}
#endif

- (void)testSetStorageSizeSetsProperties {

  // If
  long dbSize = 2 * 1024 * 1024;
  void (^completionBlock)(BOOL) = ^(__unused BOOL success) {
  };

  // When
  [MSAppCenter setMaxStorageSize:dbSize completionHandler:completionBlock];

  // Then
  XCTAssertNotNil([MSAppCenter sharedInstance].requestedMaxStorageSizeInBytes);
  XCTAssertEqualObjects(@(dbSize), [MSAppCenter sharedInstance].requestedMaxStorageSizeInBytes);
  XCTAssertNotNil([MSAppCenter sharedInstance].maxStorageSizeCompletionHandler);
  XCTAssertEqual(completionBlock, [MSAppCenter sharedInstance].maxStorageSizeCompletionHandler);
}

- (void)testSetStorageHandlerCannotBeCalledAfterStart {

  // If
  [MSAppCenter start:MS_UUID_STRING withServices:nil];
  long dbSize = 2 * 1024 * 1024;

  // When
  [MSAppCenter setMaxStorageSize:dbSize
               completionHandler:^(BOOL success) {
                 // Then
                 XCTAssertFalse(success);
               }];
}

- (void)testSetStorageHandlerCanOnlyBeCalledOnce {

  // If
  long dbSize = 2 * 1024 * 1024;

  // When
  [MSAppCenter setMaxStorageSize:dbSize
               completionHandler:^(__unused BOOL success){
               }];
  [MSAppCenter setMaxStorageSize:dbSize + 1
               completionHandler:^(__unused BOOL success){
               }];

  // Then
  XCTAssertEqual(dbSize, [[MSAppCenter sharedInstance].requestedMaxStorageSizeInBytes longValue]);
}

- (void)testSetStorageSizeBelowMaximumLogSizeFails {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler invoked."];

  // When
  [MSAppCenter setMaxStorageSize:10
               completionHandler:^(BOOL success) {
                 // Then
                 XCTAssertFalse(success);
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testSetValidUserIdForAppCenter {

  // If
  NSString *userId = @"user123";

  // When
  [MSAppCenter setUserId:userId];

  // Then
  XCTAssertNil([[MSUserIdContext sharedInstance] userId]);

  // When
  [MSAppCenter startFromLibraryWithServices:@[ MSMockService.class ]];
  [MSAppCenter setUserId:userId];

  // Then
  XCTAssertNil([[MSUserIdContext sharedInstance] userId]);

  // When
  [MSAppCenter configureWithAppSecret:@"AppSecret"];
  [MSAppCenter setUserId:userId];

  // Then
  XCTAssertEqual([[MSUserIdContext sharedInstance] userId], userId);

  // When
  [MSAppCenter setUserId:nil];

  // Then
  XCTAssertNil([[MSUserIdContext sharedInstance] userId]);
}

- (void)testSetUserIdWithoutSecret {

  // If
  NSString *userId = @"user123";

  // When
  [MSAppCenter configure];
  [MSAppCenter setUserId:userId];

  // Then
  XCTAssertNil([[MSUserIdContext sharedInstance] userId]);
}

- (void)testSetInvalidUserIdForAppCenter {

  // If
  NSString *userId = @"";
  for (int i = 0; i < 257; i++) {
    userId = [userId stringByAppendingString:@"x"];
  }
  [MSAppCenter configureWithAppSecret:@"AppSecret"];

  // When
  [MSAppCenter setUserId:userId];

  // Then
  XCTAssertNil([[MSUserIdContext sharedInstance] userId]);
}

- (void)testSetInvalidUserIdForTransmissionTarget {

  // If
  [MSAppCenter configureWithAppSecret:@"target=transmissionTargetToken"];

  // When
  // Set an empty userId
  [MSAppCenter setUserId:@""];

  // Then
  XCTAssertNil([[MSUserIdContext sharedInstance] userId]);

  // When
  // Set another empty userId
  [MSAppCenter setUserId:@"c:"];

  // Then
  XCTAssertNil([[MSUserIdContext sharedInstance] userId]);

  // When
  // Set a userId with invalid prefix
  [MSAppCenter setUserId:@"foobar:alice"];

  // Then
  XCTAssertNil([[MSUserIdContext sharedInstance] userId]);

  // When
  // Set a valid userId without prefix
  [MSAppCenter setUserId:@"alice"];

  // Then
  XCTAssertEqual([[MSUserIdContext sharedInstance] userId], @"alice");

  // When
  // Set a valid userId with prefix c:
  [MSAppCenter setUserId:@"c:alice"];

  // Then
  XCTAssertEqual([[MSUserIdContext sharedInstance] userId], @"c:alice");

  // When
  // Set a userId with invalid prefix again
  [MSAppCenter setUserId:@"foobar:alice"];

  // Then
  // Current userId shouldn't be overridden by the invalid one.
  XCTAssertEqual([[MSUserIdContext sharedInstance] userId], @"c:alice");
}

- (void)testNoUserIdWhenSetUserIdIsNotCalledInNextVersion {

  // If
  // An app calls setUserId in version 1.
  __block NSDate *date;
  NSMutableArray *history = [NSMutableArray new];
  [history addObject:[[MSUserIdHistoryInfo alloc] initWithTimestamp:[NSDate dateWithTimeIntervalSince1970:0] andUserId:@"alice"]];
  [history addObject:[[MSUserIdHistoryInfo alloc] initWithTimestamp:[NSDate dateWithTimeIntervalSince1970:3000] andUserId:@"bob"]];
  [self.settingsMock setObject:[NSKeyedArchiver archivedDataWithRootObject:history] forKey:@"UserIdHistory"];
  [MSUserIdContext resetSharedInstance];

  // When
  // setUserId call is removed in version 2.
  id dateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:4000];
    [invocation setReturnValue:&date];
  });
  [MSAppCenter configureWithAppSecret:@"AppSecret"];
  [dateMock stopMocking];

  // Then
  XCTAssertNil([[MSUserIdContext sharedInstance] userIdAt:[NSDate dateWithTimeIntervalSince1970:5000]]);

  // When
  // Version 2 app launched again.
  [MSUserIdContext resetSharedInstance];
  dateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([dateMock date])).andDo(^(NSInvocation *invocation) {
    date = [[NSDate alloc] initWithTimeIntervalSince1970:7000];
    [invocation setReturnValue:&date];
  });
  [MSAppCenter configureWithAppSecret:@"AppSecret"];
  [dateMock stopMocking];

  // Then
  XCTAssertNil([[MSUserIdContext sharedInstance] userIdAt:[NSDate dateWithTimeIntervalSince1970:5000]]);
}

@end
