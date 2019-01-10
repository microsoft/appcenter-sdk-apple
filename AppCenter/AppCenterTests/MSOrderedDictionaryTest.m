#import "MSOrderedDictionary.h"
#import "MSTestFrameworks.h"

@interface MSOrderedDictionaryTests : XCTestCase

@property(nonatomic) MSOrderedDictionary *sut;

@end

@implementation MSOrderedDictionaryTests

- (void)setUp {
  [super setUp];

  self.sut = [MSOrderedDictionary new];
}

- (void)tearDown {
  [super tearDown];

  [self.sut removeAllObjects];
}

- (void)testAddingOrderedObjects {

  // When
  [self.sut setObject:@"value1" forKey:@"key1"];
  [self.sut setObject:@"value2" forKey:@"key2"];

  // Then
  NSEnumerator *keyEnumerator = [self.sut keyEnumerator];
  XCTAssertTrue(self.sut.count == 2);
  XCTAssertTrue([[keyEnumerator nextObject] isEqualToString:@"key1"]);
  XCTAssertTrue([[keyEnumerator nextObject] isEqualToString:@"key2"]);
  XCTAssertNil([keyEnumerator nextObject]);
  XCTAssertEqual([self.sut objectForKey:@"key1"], @"value1");
  XCTAssertEqual([self.sut objectForKey:@"key2"], @"value2");
}

- (void)testEmptyDictionariesAreEqual {
  
  // If
  MSOrderedDictionary* other = [MSOrderedDictionary new];
  
  // Then
  XCTAssertTrue([self.sut isEqualToDictionary:other]);
}

- (void)testEqualDictionariesOfDifferentTypesAreEqual {
  
  // If
  NSDictionary* other = [NSDictionary new];
  
  // Then
  XCTAssertTrue([self.sut isEqualToDictionary:other]);
}

- (void)testDifferentLengthDictionariesNotEqual {
  
  // If
  MSOrderedDictionary* other = [MSOrderedDictionary new];
  [other setObject:@"value" forKey:@"key"];
  
  // Then
  XCTAssertFalse([self.sut isEqualToDictionary:other]);
}

- (void)testDifferentKeyOrdersNotEqual {
  
  // If
  MSOrderedDictionary* other = [MSOrderedDictionary new];
  [other setObject:@"value1" forKey:@"key1"];
  [other setObject:@"value2" forKey:@"key2"];
  
  // When
  [self.sut setObject:@"value2" forKey:@"key2"];
  [self.sut setObject:@"value1" forKey:@"key1"];
  
  // Then
  XCTAssertFalse([self.sut isEqualToDictionary:other]);
}

- (void)testDifferentValuesForKeysNotEqual {
  
  // If
  MSOrderedDictionary* other = [MSOrderedDictionary new];
  [other setObject:@"value1" forKey:@"key1"];
  [other setObject:@"value2" forKey:@"key2"];
  
  // When
  [self.sut setObject:@"value1" forKey:@"key2"];
  [self.sut setObject:@"value2" forKey:@"key1"];
  
  // Then
  XCTAssertFalse([self.sut isEqualToDictionary:other]);
}

- (void)testEqualDictionaries {
  
  // If
  MSOrderedDictionary* other = [MSOrderedDictionary new];
  [other setObject:@"value1" forKey:@"key1"];
  [other setObject:@"value2" forKey:@"key2"];
  
  // When
  [self.sut setObject:@"value1" forKey:@"key1"];
  [self.sut setObject:@"value2" forKey:@"key2"];
  
  // Then
  XCTAssertTrue([self.sut isEqualToDictionary:other]);
}

@end
