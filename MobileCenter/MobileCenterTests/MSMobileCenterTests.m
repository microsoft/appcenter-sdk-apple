#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"
#import "MSMobileCenterPrivate.h"
#import "MSServiceInternal.h"

static NSString *const kMSInstallIdStringExample = @"F18499DA-5C3D-4F05-B4E8-D8C9C06A6F09";

// NSUUID can return this nullified InstallId while creating a UUID from a nil string, we want to avoid this.
static NSString *const kMSNullifiedInstallIdString = @"00000000-0000-0000-0000-000000000000";

@interface MSMobileCenterTest : XCTestCase

@property(nonatomic) MSMobileCenter *sut;
@property(nonatomic) id settingsMock;
@property(nonatomic) NSString *installId;

@end

@implementation MSMobileCenterTest

- (void)setUp {
  [super setUp];

  // System Under Test.
  self.sut = [[MSMobileCenter alloc] init];

  self.settingsMock = OCMClassMock([NSUserDefaults class]);
  OCMStub([self.settingsMock standardUserDefaults]).andReturn(self.settingsMock);
  OCMStub([self.settingsMock setObject:[OCMArg any]
                                forKey:[OCMArg isEqual:@"MSInstallId"]]).andDo(^(NSInvocation *invocation) {
    id object;
    [invocation getArgument:&object atIndex:2];
    self.installId = object;
  });
  OCMStub([self.settingsMock objectForKey:[OCMArg isEqual:@"MSInstallId"]]).andCall(self,@selector(getInstallId));
}

- (void)tearDown {
  [super tearDown];
}

-(NSString*)getInstallId{
  return self.installId;
}

#pragma mark - install Id

- (void)testGetInstallIdFromEmptyStorage {

  // If
  // InstallId is removed from the storage.
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMSInstallIdKey];

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
  [[NSUserDefaults standardUserDefaults] setObject:MS_UUID_FROM_STRING(@"42") forKey:kMSInstallIdKey];

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
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMSInstallIdKey];

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
  NSArray<MSServiceAbstract *> *sorted = [self.sut sortServices:@[ mockServiceDefaultPrio, mockServiceMaxPrio ]];

  // Then
  XCTAssertTrue([sorted[0] initializationPriority] == MSInitializationPriorityMax);
  XCTAssertTrue([sorted[1] initializationPriority] == MSInitializationPriorityDefault);
}

@end
