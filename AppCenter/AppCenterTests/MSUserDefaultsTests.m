// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSLoggerInternal.h"
#import "MSWrapperLogger.h"
#import "MSUserDefaults.h"
#import "MSTestFrameworks.h"

@interface MSUserDefaultsTests : XCTestCase

@end

static NSString *const kMSAppCenterUserDefaultsMigratedKey = @"MSAppCenterUserDefaultsMigratedKey";
static NSString *const kMSUserDefaultsPrefix = @"MS";

@implementation MSUserDefaultsTests

- (void)setUp {
    NSArray *userDefaultKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
    for(NSString *key in userDefaultKeys) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
    [MSUserDefaults resetSharedInstance];
}

- (void)testMigrateSettingsOnInit {
    
    // If
    NSString *testValue = @"testValue";
    [[NSUserDefaults standardUserDefaults] setObject:testValue forKey:@"pastDevicesKey"];
    
    // When
    [MSUserDefaults shared];
    
    // Then
    XCTAssertEqual(testValue, [[NSUserDefaults standardUserDefaults] objectForKey:@"MSPastDevicesKey"]);
}

- (void)testSettingsAlreadyMigrated {
    
    // If
    [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:kMSAppCenterUserDefaultsMigratedKey];
    
    // When
    [MSUserDefaults shared];
    
    // Then
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:@"MSPastDevicesKey"]);
}

- (void)testMSIsAppendedOnSetAndGet {
    
    // If
    NSString *value = @"testValue";
    NSString *key = @"testKey";
    
    // When
    MSUserDefaults *userDefaults = [MSUserDefaults shared];
    [userDefaults setObject:value forKey:key];
    
    // Then
    XCTAssertEqual(value, [[NSUserDefaults standardUserDefaults] objectForKey:[kMSUserDefaultsPrefix stringByAppendingString:key]]);
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:key]);
    XCTAssertEqual(value, [userDefaults objectForKey:key]);
    
    // When
    [userDefaults removeObjectForKey:key];
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:[kMSUserDefaultsPrefix stringByAppendingString:key]]);
}

- (void)testMigrateUserDefaultSettings {
    
    // If
    NSDictionary *keys = @{
      @"okeyTest1" : @"MSKeyTest1",
      @"okeyTest2" : @"MSKeyTest2",
      @"okeyTest3" : @"MSKeyTest3",
      @"okeyTest4" : @"MSKeyTest4"
    };
    MSUserDefaults *userDefaults = [MSUserDefaults shared];
    NSArray *oldKeysArray = [keys allKeys];
    NSArray *expectedKeysArray = [keys allValues];
    for (NSUInteger i = 0; i < [keys count]; i++) {
      [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"Test %lu", (unsigned long)i]
                            forKey:oldKeysArray[i]];
    }
    // Check that in MSUserDefaultsTest the same keys.
    NSArray *userDefaultKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
    for(NSString *oldKey in oldKeysArray) {
        XCTAssertTrue([userDefaultKeys containsObject:oldKey]);
    }
    XCTAssertFalse([userDefaultKeys containsObject:expectedKeysArray]);
    
    // When
    [userDefaults migrateSettingsKeys:keys];

    // Then
    userDefaultKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
    XCTAssertFalse([userDefaultKeys containsObject:oldKeysArray]);
    for(NSString *expectedKey in expectedKeysArray) {
        XCTAssertTrue([userDefaultKeys containsObject:expectedKey]);
    }
    for(NSString *oldKey in oldKeysArray) {
        XCTAssertFalse([userDefaultKeys containsObject:oldKey]);
    }
}

@end
