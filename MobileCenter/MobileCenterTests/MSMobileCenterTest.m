#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"
#import "MSUtils.h"
#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

static NSString *const kSMInstallIdStringExample = @"F18499DA-5C3D-4F05-B4E8-D8C9C06A6F09";

// NSUUID can return this nullified InstallId while creating a UUID from a nil string, we want to avoid this.
static NSString *const kSMNullifiedInstallIdString = @"00000000-0000-0000-0000-000000000000";

@interface MSMobileCenterTest : XCTestCase

@property(nonatomic) MSMobileCenter *sut;

@end

@implementation MSMobileCenterTest

- (void)setUp {
  [super setUp];

  // System Under Test.
  self.sut = [[MSMobileCenter alloc] init];
}

- (void)tearDown {
  [super tearDown];
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
  assertThat(installIdString, isNot(kSMNullifiedInstallIdString));
}

- (void)testGetInstallIdFromStorage {

  // If
  // Expected installId is added to the storage.
  [[NSUserDefaults standardUserDefaults] setObject:kSMInstallIdStringExample forKey:kMSInstallIdKey];

  // When
  NSUUID *installId = self.sut.installId;

  // Then
  assertThat(installId, is(kMSUUIDFromString(kSMInstallIdStringExample)));
  assertThat([installId UUIDString], is(kSMInstallIdStringExample));
}

- (void)testGetInstallIdFromBadStorage {

  // If
  // Unexpected installId is added to the storage.
  [[NSUserDefaults standardUserDefaults] setObject:kMSUUIDFromString(@"42") forKey:kMSInstallIdKey];

  // When
  NSUUID *installId = self.sut.installId;
  NSString *installIdString = [installId UUIDString];

  // Then
  assertThat(installId, notNilValue());
  assertThat(installIdString, notNilValue());
  assertThatInteger([installIdString length], greaterThan(@(0)));
  assertThat(installIdString, isNot(kSMNullifiedInstallIdString));
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
  assertThat(installId1String, isNot(kSMNullifiedInstallIdString));

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
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMSInstallIdKey];

  // When
  NSUUID *installId1 = self.sut.installId;
  self.sut = [[MSMobileCenter alloc] init];
  NSUUID *installId2 = self.sut.installId;

  // Then
  assertThat(installId1, is(installId2));
  assertThat([installId1 UUIDString], is([installId2 UUIDString]));
}

- (void)testSetServerUrl {
  NSString *fakeUrl = @"http://testUrl:1234";
  [MSMobileCenter setServerUrl:fakeUrl];
  [MSMobileCenter start:[[NSUUID UUID] UUIDString] withFeatures:nil];
  XCTAssertTrue([[[MSMobileCenter sharedInstance] serverUrl] isEqualToString:fakeUrl]);
}

- (void)testDefaultServerUrl {
  [MSMobileCenter start:[[NSUUID UUID] UUIDString] withFeatures:nil];
  XCTAssertTrue([[[MSMobileCenter sharedInstance] serverUrl] isEqualToString:@"https://in.sonoma.hockeyapp.com"]);
}
@end
