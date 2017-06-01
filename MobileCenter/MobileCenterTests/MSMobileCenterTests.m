#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#else
#import <OCHamcrest/OCHamcrest.h>
#endif
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"
#import "MSMobileCenterPrivate.h"
#if TARGET_OS_IPHONE
#import "MSMockCustomAppDelegate.h"
#import "MSMockOriginalAppDelegate.h"
#else
// TODO: ApplicationDelegate is not yet implemented for macOS.
#endif
#import "MSMockUserDefaults.h"
#import "MSLogManager.h"
#import "MSCustomProperties.h"
#import "MSCustomPropertiesLog.h"

static NSString *const kMSInstallIdStringExample = @"F18499DA-5C3D-4F05-B4E8-D8C9C06A6F09";

// NSUUID can return this nullified InstallId while creating a UUID from a nil string, we want to avoid this.
static NSString *const kMSNullifiedInstallIdString = @"00000000-0000-0000-0000-000000000000";

@interface MSMobileCenterTest : XCTestCase

@property(nonatomic) MSMobileCenter *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) NSString *installId;

@end

@implementation MSMobileCenterTest

- (void)setUp {
  [super setUp];

  // System Under Test.
  self.sut = [[MSMobileCenter alloc] init];

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
  self.sut = [[MSMobileCenter alloc] init];
  NSUUID *installId2 = self.sut.installId;

  // Then
  assertThat(installId1, is(installId2));
  assertThat([installId1 UUIDString], is([installId2 UUIDString]));
}

- (void)testSetLogUrl {
  [MSMobileCenter resetSharedInstance];
  NSString *fakeUrl = @"http://testUrl:1234";
  [MSMobileCenter setLogUrl:fakeUrl];
  [MSMobileCenter start:MS_UUID_STRING withServices:nil];
  XCTAssertTrue([[[MSMobileCenter sharedInstance] logUrl] isEqualToString:fakeUrl]);
}

- (void)testDefaultLogUrl {
  [MSMobileCenter resetSharedInstance];
  [MSMobileCenter start:MS_UUID_STRING withServices:nil];
  XCTAssertTrue([[[MSMobileCenter sharedInstance] logUrl] isEqualToString:@"https://in.mobile.azure.com"]);
}

- (void)testSetCustomProperties {

  // If
  [MSMobileCenter start:MS_UUID_STRING withServices:nil];
  id logManager = OCMProtocolMock(@protocol(MSLogManager));
  OCMStub([logManager processLog:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]] forGroupId:[OCMArg any]])
      .andDo(nil);
  [MSMobileCenter sharedInstance].logManager = logManager;

  // When
  MSCustomProperties *customProperties = [MSCustomProperties new];
  [customProperties setString:@"test" forKey:@"test"];
  [MSMobileCenter setCustomProperties:customProperties];

  // Then
  OCMVerify([logManager processLog:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]] forGroupId:[OCMArg any]]);

  // When
  // Not allow processLog more
  OCMReject([logManager processLog:[OCMArg isKindOfClass:[MSCustomPropertiesLog class]] forGroupId:[OCMArg any]]);
  [MSMobileCenter setCustomProperties:nil];
  [MSMobileCenter setCustomProperties:[MSCustomProperties new]];
}

- (void)testConfigureWithAppSecret {
  [MSMobileCenter configureWithAppSecret:@"App-Secret"];
  XCTAssertTrue([MSMobileCenter isConfigured]);
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

- (void)testAppIsBackgrounded {

  // If
  id<MSLogManager> logManager = OCMProtocolMock(@protocol(MSLogManager));
  [self.sut configure:@"AnAppSecret"];
  self.sut.logManager = logManager;

  // When
  [[NSNotificationCenter defaultCenter]
#if TARGET_OS_IPHONE
      postNotificationName:UIApplicationDidEnterBackgroundNotification
#else
      postNotificationName:NSApplicationDidHideNotification
#endif
                    object:self.sut];
  // Then
  OCMVerify([logManager suspend]);
}

- (void)testAppIsForegrounded {

  // If
  id<MSLogManager> logManager = OCMProtocolMock(@protocol(MSLogManager));
  [self.sut configure:@"AnAppSecret"];
  self.sut.logManager = logManager;

  // When
  [[NSNotificationCenter defaultCenter]
#if TARGET_OS_IPHONE
      postNotificationName:UIApplicationWillEnterForegroundNotification
#else
      postNotificationName:NSApplicationDidUnhideNotification
#endif

                    object:self.sut];
  // Then
  OCMVerify([logManager resume]);
}

@end
