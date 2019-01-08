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
  XCTAssertTrue([[keyEnumerator nextObject] isEqualToString:@"value1"]);
  XCTAssertTrue([[keyEnumerator nextObject] isEqualToString:@"value2"]);
  XCTAssertNil([keyEnumerator nextObject]);
  XCTAssertEqual([self.sut objectForKey:@"key1"], @"value1");
  XCTAssertEqual([self.sut objectForKey:@"key2"], @"value2");
}

@end
