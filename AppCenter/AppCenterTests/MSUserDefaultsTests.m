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
  XCTAssertEqual(testValue, [[NSUserDefaults standardUserDefaults] objectForKey:@"MSAppCenterPastDevices"]);

  // Verify it migrates no more.
  // If
  NSString *testValue2 = @"testValue2";
  [[NSUserDefaults standardUserDefaults] setObject:testValue2 forKey:@"pastDevicesKey"];
  [MSAppCenterUserDefaults resetSharedInstance];

  // When
  [MSAppCenterUserDefaults shared];

  // Then
  XCTAssertEqual(testValue, [[NSUserDefaults standardUserDefaults] objectForKey:@"MSAppCenterPastDevices"]);
}

- (void)testSettingsAlreadyMigrated {

  // If
  NSString *testValue = @"testValue";
  [[NSUserDefaults standardUserDefaults] setObject:testValue forKey:@"pastDevicesKey"];
  [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:kMSAppCenterUserDefaultsMigratedKey];

  // When
  [MSAppCenterUserDefaults shared];

  // Then
  XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:@"MSAppCenterPastDevices"]);
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

  NSArray *suffixes = @[ @"-suffix1", @"/suffix2", @"suffix3" ];
  NSString *wildcard = @"okeyTestWildcard";
  NSString *expectedWildcard = @"MSAppCenterOkeyTestWildcard";
  // If
  NSDictionary *keys = @{
    @"okeyTest1" : @"MSAppCenterKeyTest1",
    @"okeyTest2" : @"MSAppCenterKeyTest2",
    @"okeyTest3" : @"MSAppCenterKeyTest3",
    @"okeyTest4" : @"MSAppCenterKeyTest4",
    [MSUserDefaultsWildcardKey stringWithFormat:expectedWildcard] : expectedWildcard
  };

  MSAppCenterUserDefaults *userDefaults = [MSAppCenterUserDefaults shared];
  NSMutableArray *oldKeysArray = [[keys allKeys] mutableCopy];
  NSMutableArray *expectedKeysArray = [[keys allValues] mutableCopy];
  for (NSString *suffix in suffixes) {
    [expectedKeysArray addObject:[expectedWildcard stringByAppendingString:suffix]];
    [oldKeysArray addObject:[wildcard stringByAppendingString:suffix]];
  }
  for (NSUInteger i = 0; i < [keys count]; i++) {
    if ([oldKeysArray[i] isKindOfClass:[MSUserDefaultsWildcardKey class]]) {
      continue;
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"Test %tu", i] forKey:oldKeysArray[i]];
  }
  for (NSString *suffix in suffixes) {
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"Test %@", suffix]
                                              forKey:[wildcard stringByAppendingString:suffix]];
  }

  // Check that in MSUserDefaultsTest the same keys.
  NSArray *userDefaultKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
  for (NSString *oldKey in oldKeysArray) {
    if ([oldKey isKindOfClass:[MSUserDefaultsWildcardKey class]]){
      continue;
    }
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
    if ([expectedKey isEqualToString:expectedWildcard]) {
      continue;
    }
    XCTAssertTrue([userDefaultKeys containsObject:expectedKey]);
  }
  for (NSString *oldKey in oldKeysArray) {
    if ([oldKey isKindOfClass:[MSUserDefaultsWildcardKey class]]) {
      continue;
    }
    XCTAssertFalse([userDefaultKeys containsObject:oldKey]);
  }
}

@end
