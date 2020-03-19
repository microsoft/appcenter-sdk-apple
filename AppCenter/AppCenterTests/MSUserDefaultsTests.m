// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSLoggerInternal.h"
#import "MSWrapperLogger.h"
#import "MSUserDefaults.h"
#import "MSTestFrameworks.h"

@interface MSUserDefaultsTests : XCTestCase

@end

@implementation MSUserDefaultsTests

- (void)testMigrateUserDefaultSettings {
    
    // If
    NSArray *oldKeysArray = @[@"keyTest1", @"kMSKeyTest2", @"NSKeyTest3", @"MSKeyTest4"];
    NSArray *expectedKeysArray = @[@"KeyTest1", @"SKeyTest2", @"KeyTest3", @"KeyTest4"];
    MSUserDefaults *userDefaults = [MSUserDefaults new];
    for (NSUInteger i = 0; i < [oldKeysArray count]; i++) {
        [userDefaults updateObject:[NSString stringWithFormat:@"Test %lu", (unsigned long)i]
                            forKey:oldKeysArray[i]];
    }
    // Check that in MSUserDefaultsTest the same keys.
    NSArray *userDefaultKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
    XCTAssertTrue([userDefaultKeys containsObject:oldKeysArray]);
    XCTAssertFalse([userDefaultKeys containsObject:expectedKeysArray]);
    // Update values by keys.
    for (NSUInteger i = 0; i < [oldKeysArray count]; i++) {
        [userDefaults updateObject:[NSString stringWithFormat:@"UpdateTest %lu", (unsigned long)i]
                            forKey:oldKeysArray[i]];
    }
    // Check that in MSUserDefaultsTest the keys was changed.
    userDefaultKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
    XCTAssertFalse([userDefaultKeys containsObject:oldKeysArray]);
    XCTAssertTrue([userDefaultKeys containsObject:expectedKeysArray]);
}

@end
