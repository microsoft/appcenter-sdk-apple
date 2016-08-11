#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVABinary.h"

@interface AVABinaryTests : XCTestCase

@end

@implementation AVABinaryTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  AVABinary *sut = [self binary];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"id"], equalTo(sut.binaryId));
  assertThat(actual[@"startAddress"], equalTo(sut.startAddress));
  assertThat(actual[@"endAddress"], equalTo(sut.endAddress));
  assertThat(actual[@"name"], equalTo(sut.name));
  assertThat(actual[@"architecture"], equalTo(sut.architecture));
  assertThat(actual[@"path"], equalTo(sut.path));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  AVABinary *sut = [self binary];

  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([AVABinary class]));
  
  AVABinary *actualBinary = actual;
  assertThat(actualBinary.binaryId, equalTo(sut.binaryId));
  assertThat(actualBinary.startAddress, equalTo(sut.startAddress));
  assertThat(actualBinary.endAddress, equalTo(sut.endAddress));
  assertThat(actualBinary.name, equalTo(sut.name));
  assertThat(actualBinary.architecture, equalTo(sut.architecture));
  assertThat(actualBinary.path, equalTo(sut.path));
}

#pragma mark - Helper

- (AVABinary *)binary {
  NSString *binaryId = @"binaryId";
  NSString *startAddress = @"startAddress";
  NSString *endAddress = @"endAddress";
  NSString *name = @"name";
  NSString *architecture = @"architecture";
  NSString *path = @"path";
  
  AVABinary *binary = [AVABinary new];
  binary.binaryId = binaryId;
  binary.startAddress = startAddress;
  binary.endAddress = endAddress;
  binary.name = name;
  binary.architecture = architecture;
  binary.path = path;
  
  return binary;
}

@end
