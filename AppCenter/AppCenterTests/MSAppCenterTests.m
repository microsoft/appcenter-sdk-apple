#include <Foundation/Foundation.h>
#if !TARGET_OS_TV
#import "MSCustomProperties.h"
#import "MSCustomPropertiesLog.h"
#endif
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSAppCenterPrivate.h"
#import "MSLogManagerDefault.h"
#import "MSMockService.h"
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

- (void)testSetLogUrl {
  [MSAppCenter resetSharedInstance];
  NSString *fakeUrl = @"http://testUrl:1234";
  [MSAppCenter setLogUrl:fakeUrl];
  [MSAppCenter start:MS_UUID_STRING withServices:nil];
  XCTAssertTrue([[[MSAppCenter sharedInstance] logUrl] isEqualToString:fakeUrl]);
}

- (void)testDefaultLogUrl {
  [MSAppCenter resetSharedInstance];
  [MSAppCenter start:MS_UUID_STRING withServices:nil];
  XCTAssertTrue([[[MSAppCenter sharedInstance] logUrl] isEqualToString:@"https://in.appcenter.ms"]);
}

- (void)testSdkVersion {
  NSString *version = [NSString stringWithUTF8String:APP_CENTER_C_VERSION];
  XCTAssertTrue([[MSAppCenter sdkVersion] isEqualToString:version]);
}

#if !TARGET_OS_TV
- (void)testSetCustomProperties {

  // If
  [MSAppCenter start:MS_UUID_STRING withServices:nil];
  id logManager = OCMProtocolMock(@protocol(MSLogManager));
  OCMStub([logManager processLog:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]] forGroupId:OCMOCK_ANY])
      .andDo(nil);
  [MSAppCenter sharedInstance].logManager = logManager;

  // When
  MSCustomProperties *customProperties = [MSCustomProperties new];
  [customProperties setString:@"test" forKey:@"test"];
  [MSAppCenter setCustomProperties:customProperties];

  // Then
  OCMVerify([logManager processLog:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]] forGroupId:OCMOCK_ANY]);

  // When
  // Not allow processLog more
  OCMReject([logManager processLog:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]] forGroupId:OCMOCK_ANY]);
  [MSAppCenter setCustomProperties:nil];
  [MSAppCenter setCustomProperties:[MSCustomProperties new]];

  // Then
  OCMVerifyAll(logManager);
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

- (void)testStartWithoutServices {

  // If
  id logManager = OCMClassMock([MSLogManagerDefault class]);
  OCMStub([logManager alloc]).andReturn(logManager);
  OCMStub([logManager initWithAppSecret:[OCMArg any] installId:[OCMArg any] logUrl:[OCMArg any]]).andReturn(logManager);

  // Not allow processLog.
  OCMReject([logManager processLog:[OCMArg isKindOfClass:[MSStartServiceLog class]] forGroupId:[OCMArg any]]);

  // When
  [MSAppCenter start:MS_UUID_STRING withServices:nil];

  // Then
  OCMVerifyAll(logManager);

  // Clear
  [logManager stopMocking];
}

- (void)testStartServiceLogIsSentAfterStartService {

  // If
  [MSAppCenter start:MS_UUID_STRING withServices:nil];
  id logManager = OCMProtocolMock(@protocol(MSLogManager));
  OCMStub([logManager processLog:[OCMArg isKindOfClass:[MSStartServiceLog class]] forGroupId:OCMOCK_ANY]).andDo(nil);
  [MSAppCenter sharedInstance].logManager = logManager;

  // When
  [MSAppCenter startService:MSMockService.class];

  // Then
  OCMVerify([logManager processLog:[OCMArg isKindOfClass:[MSStartServiceLog class]] forGroupId:OCMOCK_ANY]);
}

- (void)testStartServiceLogWithDisabledCore {
  
  // If
  id logManager = OCMClassMock([MSLogManagerDefault class]);
  OCMStub([logManager alloc]).andReturn(logManager);
  OCMStub([logManager initWithAppSecret:[OCMArg any] installId:[OCMArg any] logUrl:[OCMArg any]]).andReturn(logManager);
  
  // Not allow processLog.
  OCMReject([logManager processLog:[OCMArg isKindOfClass:[MSStartServiceLog class]] forGroupId:[OCMArg any]]);
  
  // When
  [MSAppCenter start:MS_UUID_STRING withServices:nil];
  [MSAppCenter setEnabled:NO];
  [MSAppCenter startService:MSMockService.class];
  
  // Then
  OCMVerifyAll(logManager);
  
  // Clear
  [logManager stopMocking];
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

@end
