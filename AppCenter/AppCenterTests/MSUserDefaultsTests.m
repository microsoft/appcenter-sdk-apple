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

static NSString *const kMSAppCenterUserDefaultsMigratedKey = @"MSAppCenter310AppCenterUserDefaultsMigratedKey";

@implementation MSUserDefaultsTests

- (void)setUp {
  for (NSString *key in [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]) {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
  }
  [MSAppCenterUserDefaults resetSharedInstance];
}

- (void)testSettingsAlreadyMigrated {

  // If
  NSString *testValue = @"testValue";
  [[NSUserDefaults standardUserDefaults] setObject:testValue forKey:@"pastDevicesKey"];
  [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kMSAppCenterUserDefaultsMigratedKey];

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
    @"MSAppCenterKeyTest1" : @"okeyTest1",
    @"MSAppCenterKeyTest2" : @"okeyTest2",
    @"MSAppCenterKeyTest3" : @"okeyTest3",
    @"MSAppCenterKeyTest4" : @"okeyTest4",
    expectedWildcard : MSPrefixKeyFrom(wildcard)
  };
  MSAppCenterUserDefaults *userDefaults = [MSAppCenterUserDefaults shared];
  NSMutableArray *expectedKeysArray = [[keys allKeys] mutableCopy];
  NSMutableArray *oldKeysArray = [[keys allValues] mutableCopy];
  for (NSString *suffix in suffixes) {
    [expectedKeysArray addObject:[expectedWildcard stringByAppendingString:suffix]];
    [oldKeysArray addObject:[wildcard stringByAppendingString:suffix]];
  }
  for (NSUInteger i = 0; i < [keys count]; i++) {
    if ([oldKeysArray[i] isKindOfClass:[MSUserDefaultsPrefixKey class]]) {
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
    if ([oldKey isKindOfClass:[MSUserDefaultsPrefixKey class]]) {
      continue;
    }
    XCTAssertTrue([userDefaultKeys containsObject:oldKey]);
  }
  XCTAssertFalse([userDefaultKeys containsObject:expectedKeysArray]);

  // When
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMSAppCenterUserDefaultsMigratedKey];
  [userDefaults migrateKeys:keys forService:@"AppCenter"];

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
    if ([oldKey isKindOfClass:[MSUserDefaultsPrefixKey class]]) {
      continue;
    }
    XCTAssertFalse([userDefaultKeys containsObject:oldKey]);
  }
}

@end
