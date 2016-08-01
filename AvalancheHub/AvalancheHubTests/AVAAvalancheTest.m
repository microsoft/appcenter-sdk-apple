#import "AVAAvalanche.h"
#import "AVAAvalanchePrivate.h"
#import "AVAUtils.h"
#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

static NSString *const kAVAInstallIdStringExample = @"F18499DA-5C3D-4F05-B4E8-D8C9C06A6F09";

// NSUUID can return this nullified InstallId while creating a UUID from a nil string, we want to avoid this.
static NSString *const kAVANullifiedInstallIdString = @"00000000-0000-0000-0000-000000000000";

@interface AVAAvalancheTest : XCTestCase

@property(nonatomic) AVAAvalanche *avalancheHub;

@end

@implementation AVAAvalancheTest

- (void)setUp {
  [super setUp];

  // System Under Test.
  self.avalancheHub = [[AVAAvalanche alloc] init];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - install Id

- (void)testGetInstallIdFromEmptyStorage {

  // If
  // InstallId is removed from the storage.
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAVAInstallIdKey];

  // When
  NSUUID *installId = self.avalancheHub.installId;
  NSString *installIdString = [installId UUIDString];

  // Then
  assertThat(installId, notNilValue());
  assertThat(installIdString, notNilValue());
  assertThatInteger([installIdString length], greaterThan(@(0)));
  assertThat(installIdString, isNot(kAVANullifiedInstallIdString));
}

- (void)testGetInstallIdFromStorage {

  // If
  // Expected installId is added to the storage.
  [[NSUserDefaults standardUserDefaults] setObject:kAVAInstallIdStringExample forKey:kAVAInstallIdKey];

  // When
  NSUUID *installId = self.avalancheHub.installId;

  // Then
  assertThat(installId, is(kAVAUUIDFromString(kAVAInstallIdStringExample)));
  assertThat([installId UUIDString], is(kAVAInstallIdStringExample));
}

- (void)testGetInstallIdFromBadStorage {

  // If
  // Unexpected installId is added to the storage.
  [[NSUserDefaults standardUserDefaults] setObject:kAVAUUIDFromString(@"42") forKey:kAVAInstallIdKey];

  // When
  NSUUID *installId = self.avalancheHub.installId;
  NSString *installIdString = [installId UUIDString];

  // Then
  assertThat(installId, notNilValue());
  assertThat(installIdString, notNilValue());
  assertThatInteger([installIdString length], greaterThan(@(0)));
  assertThat(installIdString, isNot(kAVANullifiedInstallIdString));
  assertThat([installId UUIDString], isNot(@"42"));
}

- (void)testGetInstallIdTwice {

  // If
  // InstallId is removed from the storage.
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAVAInstallIdKey];

  // When
  NSUUID *installId1 = self.avalancheHub.installId;
  NSString *installId1String = [installId1 UUIDString];

  // Then
  assertThat(installId1, notNilValue());
  assertThat(installId1String, notNilValue());
  assertThatInteger([installId1String length], greaterThan(@(0)));
  assertThat(installId1String, isNot(kAVANullifiedInstallIdString));

  // When
  // Second pick
  NSUUID *installId2 = self.avalancheHub.installId;

  // Then
  assertThat(installId1, is(installId2));
  assertThat([installId1 UUIDString], is([installId2 UUIDString]));
}

- (void)testInstallIdPersistency {

  // If
  // InstallId is removed from the storage.
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAVAInstallIdKey];

  // When
  NSUUID *installId1 = self.avalancheHub.installId;
  self.avalancheHub = [[AVAAvalanche alloc] init];
  NSUUID *installId2 = self.avalancheHub.installId;

  // Then
  assertThat(installId1, is(installId2));
  assertThat([installId1 UUIDString], is([installId2 UUIDString]));
}

@end
