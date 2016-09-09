#import "SNMSonoma.h"
#import "SNMSonomaInternal.h"
#import "SNMUtils.h"
#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

static NSString *const kSNMInstallIdStringExample = @"F18499DA-5C3D-4F05-B4E8-D8C9C06A6F09";

// NSUUID can return this nullified InstallId while creating a UUID from a nil string, we want to avoid this.
static NSString *const kSNMNullifiedInstallIdString = @"00000000-0000-0000-0000-000000000000";

@interface SNMSNMlancheTest : XCTestCase

@property(nonatomic) SNMSonoma *SNMlancheHub;

@end

@implementation SNMSNMlancheTest

- (void)setUp {
  [super setUp];

  // System Under Test.
  self.SNMlancheHub = [[SNMSonoma alloc] init];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - install Id

- (void)testGetInstallIdFromEmptyStorage {

  // If
  // InstallId is removed from the storage.
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSNMInstallIdKey];

  // When
  NSUUID *installId = self.SNMlancheHub.installId;
  NSString *installIdString = [installId UUIDString];

  // Then
  assertThat(installId, notNilValue());
  assertThat(installIdString, notNilValue());
  assertThatInteger([installIdString length], greaterThan(@(0)));
  assertThat(installIdString, isNot(kSNMNullifiedInstallIdString));
}

- (void)testGetInstallIdFromStorage {

  // If
  // Expected installId is added to the storage.
  [[NSUserDefaults standardUserDefaults] setObject:kSNMInstallIdStringExample forKey:kSNMInstallIdKey];

  // When
  NSUUID *installId = self.SNMlancheHub.installId;

  // Then
  assertThat(installId, is(kSNMUUIDFromString(kSNMInstallIdStringExample)));
  assertThat([installId UUIDString], is(kSNMInstallIdStringExample));
}

- (void)testGetInstallIdFromBadStorage {

  // If
  // Unexpected installId is added to the storage.
  [[NSUserDefaults standardUserDefaults] setObject:kSNMUUIDFromString(@"42") forKey:kSNMInstallIdKey];

  // When
  NSUUID *installId = self.SNMlancheHub.installId;
  NSString *installIdString = [installId UUIDString];

  // Then
  assertThat(installId, notNilValue());
  assertThat(installIdString, notNilValue());
  assertThatInteger([installIdString length], greaterThan(@(0)));
  assertThat(installIdString, isNot(kSNMNullifiedInstallIdString));
  assertThat([installId UUIDString], isNot(@"42"));
}

- (void)testGetInstallIdTwice {

  // If
  // InstallId is removed from the storage.
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSNMInstallIdKey];

  // When
  NSUUID *installId1 = self.SNMlancheHub.installId;
  NSString *installId1String = [installId1 UUIDString];

  // Then
  assertThat(installId1, notNilValue());
  assertThat(installId1String, notNilValue());
  assertThatInteger([installId1String length], greaterThan(@(0)));
  assertThat(installId1String, isNot(kSNMNullifiedInstallIdString));

  // When
  // Second pick
  NSUUID *installId2 = self.SNMlancheHub.installId;

  // Then
  assertThat(installId1, is(installId2));
  assertThat([installId1 UUIDString], is([installId2 UUIDString]));
}

- (void)testInstallIdPersistency {

  // If
  // InstallId is removed from the storage.
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSNMInstallIdKey];

  // When
  NSUUID *installId1 = self.SNMlancheHub.installId;
  self.SNMlancheHub = [[SNMSonoma alloc] init];
  NSUUID *installId2 = self.SNMlancheHub.installId;

  // Then
  assertThat(installId1, is(installId2));
  assertThat([installId1 UUIDString], is([installId2 UUIDString]));
}

@end
