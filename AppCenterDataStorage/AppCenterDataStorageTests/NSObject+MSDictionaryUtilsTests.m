// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "NSObject+MSDictionaryUtils.h"
#import "MSTestFrameworks.h"

@interface NSObjectMSDictionaryUtilsTests : XCTestCase

@end

@implementation NSObjectMSDictionaryUtilsTests

- (void)testIsDictionaryWithKeyWithNilObject {
  
  // If, When, Then
  XCTAssertFalse([(NSObject*)nil isDictionaryWithKey:@"test" keyType:[NSString class]]);
}

- (void)testIsDictionaryWithKeyWithNonDictionary {
  
  // If
  NSString *someString = @"some string";
  
  // When, Then
  XCTAssertFalse([someString isDictionaryWithKey:@"test" keyType:[NSString class]]);
}

- (void)testIsDictionaryWithDictionary {
  
  // If
  NSMutableDictionary *dictionary = [NSMutableDictionary new];
  dictionary[@"string"] = @"some string";
  dictionary[@"number"] = @42;
  dictionary[@"array"] = [NSArray new];
  
  // When, Then
  XCTAssertTrue([dictionary isDictionaryWithKey:@"string" keyType:[NSString class]]);
  XCTAssertFalse([dictionary isDictionaryWithKey:@"string" keyType:[NSNumber class]]);
  XCTAssertFalse([dictionary isDictionaryWithKey:@"string" keyType:[NSArray class]]);
  XCTAssertFalse([dictionary isDictionaryWithKey:@"number" keyType:[NSString class]]);
  XCTAssertTrue([dictionary isDictionaryWithKey:@"number" keyType:[NSNumber class]]);
  XCTAssertFalse([dictionary isDictionaryWithKey:@"number" keyType:[NSArray class]]);
  XCTAssertFalse([dictionary isDictionaryWithKey:@"array" keyType:[NSString class]]);
  XCTAssertFalse([dictionary isDictionaryWithKey:@"array" keyType:[NSNumber class]]);
  XCTAssertTrue([dictionary isDictionaryWithKey:@"array" keyType:[NSArray class]]);
}

@end
