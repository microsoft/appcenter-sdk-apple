#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAAppleBinary.h"

@interface AVAAppleBinaryTests : XCTestCase

@end

@implementation AVAAppleBinaryTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  AVAAppleBinary *sut = [self binary];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"id"], equalTo(sut.binaryId));
  assertThat(actual[@"startAddress"], equalTo(sut.startAddress));
  assertThat(actual[@"endAddress"], equalTo(sut.endAddress));
  assertThat(actual[@"name"], equalTo(sut.name));
  assertThat(actual[@"path"], equalTo(sut.path));
  assertThat(actual[@"cpuType"], equalTo(sut.cpuType));
  assertThat(actual[@"cpuSubType"], equalTo(sut.cpuSubType));

}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  AVAAppleBinary *sut = [self binary];

  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([AVAAppleBinary class]));
  
  AVAAppleBinary *actualBinary = actual;
  assertThat(actualBinary.binaryId, equalTo(sut.binaryId));
  assertThat(actualBinary.startAddress, equalTo(sut.startAddress));
  assertThat(actualBinary.endAddress, equalTo(sut.endAddress));
  assertThat(actualBinary.name, equalTo(sut.name));
  assertThat(actualBinary.path, equalTo(sut.path));
  assertThat(actualBinary.cpuType, equalTo(sut.cpuType));
  assertThat(actualBinary.cpuSubType, equalTo(sut.cpuSubType));
}

#pragma mark - Helper

- (AVAAppleBinary *)binary {
  NSString *binaryId = @"binaryId";
  NSString *startAddress = @"startAddress";
  NSString *endAddress = @"endAddress";
  NSString *name = @"name";
  NSString *path = @"path";
  NSNumber *cpuType = @12;
  NSNumber *cpuSubTybe = @23;
  
  AVAAppleBinary *binary = [AVAAppleBinary new];
  binary.binaryId = binaryId;
  binary.startAddress = startAddress;
  binary.endAddress = endAddress;
  binary.name = name;
  binary.path = path;
  binary.cpuType = cpuType;
  binary.cpuSubType = cpuSubTybe;
  
  return binary;
}

@end
