// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterUserDefaults.h"
#import "MSAppCenterUserDefaultsPrivate.h"
#import "MSLoggerInternal.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"
#import "MSWrapperLogger.h"

@interface MSUserDefaultsTests : XCTestCase

@end

static NSString *const kMSAppCenterUserDefaultsMigratedKey = @"MSAppCenter310UserDefaultsMigratedKey";

@implementation MSUserDefaultsTests

- (void)setUp {
  NSArray *userDefaultKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
  for (NSString *key in userDefaultKeys) {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
  }
  [MSAppCenterUserDefaults resetSharedInstance];
}

- (void)testMigrateSettingsOnInit {

  // If
  NSString *testValue = @"testValue";
  [[NSUserDefaults standardUserDefaults] setObject:testValue forKey:@"pastDevicesKey"];

  // When
  [MSAppCenterUserDefaults shared];

  // Then
  XCTAssertEqual(testValue, [[NSUserDefaults standardUserDefaults] objectForKey:@"MSAppCenterPastDevicesKey"]);

  // Verify it migrates no more.
  // If
  NSString *testValue2 = @"testValue2";
  [[NSUserDefaults standardUserDefaults] setObject:testValue2 forKey:@"pastDevicesKey"];
  [MSAppCenterUserDefaults resetSharedInstance];

  // When
  [MSAppCenterUserDefaults shared];

  // Then
  XCTAssertEqual(testValue, [[NSUserDefaults standardUserDefaults] objectForKey:@"MSAppCenterPastDevicesKey"]);
}

- (void)testSettingsAlreadyMigrated {

  // If
  NSString *testValue = @"testValue";
  [[NSUserDefaults standardUserDefaults] setObject:testValue forKey:@"pastDevicesKey"];
  [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:kMSAppCenterUserDefaultsMigratedKey];

  // When
  [MSAppCenterUserDefaults shared];

  // Then
  XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:@"MSAppCenterPastDevicesKey"]);
}

- (void)testPrefixIsAppendedOnSetAndGet {

  // If
  NSString *value = @"testValue";
  NSString *key = @"testKey";

  // When
  MSAppCenterUserDefaults *userDefaults = [MSAppCenterUserDefaults shared];
  [userDefaults setObject:value forKey:key];

  // Then
  XCTAssertEqual(value, [[NSUserDefaults standardUserDefaults] objectForKey:[kMSUserDefaultsPrefix stringByAppendingString:key]]);
  XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:key]);
  XCTAssertEqual(value, [userDefaults objectForKey:key]);

  // When
  [userDefaults removeObjectForKey:key];

  // Then
  XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:[kMSUserDefaultsPrefix stringByAppendingString:key]]);
}

- (void)testMigrateUserDefaultSettings {

  // If
  NSDictionary *keys = @{
    @"okeyTest1" : @"MSAppCenterKeyTest1",
    @"okeyTest2" : @"MSAppCenterKeyTest2",
    @"okeyTest3" : @"MSAppCenterKeyTest3",
    @"okeyTest4" : @"MSAppCenterKeyTest4"
  };
  MSAppCenterUserDefaults *userDefaults = [MSAppCenterUserDefaults shared];
  NSArray *oldKeysArray = [keys allKeys];
  NSArray *expectedKeysArray = [keys allValues];
  for (NSUInteger i = 0; i < [keys count]; i++) {
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"Test %tu", i] forKey:oldKeysArray[i]];
  }

  // Check that in MSUserDefaultsTest the same keys.
  NSArray *userDefaultKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
  for (NSString *oldKey in oldKeysArray) {
    XCTAssertTrue([userDefaultKeys containsObject:oldKey]);
  }
  XCTAssertFalse([userDefaultKeys containsObject:expectedKeysArray]);

  // When
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMSAppCenterUserDefaultsMigratedKey];
  [userDefaults migrateKeys:keys];

  // Then
  userDefaultKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
  XCTAssertFalse([userDefaultKeys containsObject:oldKeysArray]);
  for (NSString *expectedKey in expectedKeysArray) {
    XCTAssertTrue([userDefaultKeys containsObject:expectedKey]);
  }
  for (NSString *oldKey in oldKeysArray) {
    XCTAssertFalse([userDefaultKeys containsObject:oldKey]);
  }
}

@end
