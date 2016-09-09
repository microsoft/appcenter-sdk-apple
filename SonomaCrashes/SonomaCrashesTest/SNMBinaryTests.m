#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMBinary.h"

@interface SNMBinaryTests : XCTestCase

@end

@implementation SNMBinaryTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  SNMBinary *sut = [self binary];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"id"], equalTo(sut.binaryId));
  assertThat(actual[@"startAddress"], equalTo(sut.startAddress));
  assertThat(actual[@"endAddress"], equalTo(sut.endAddress));
  assertThat(actual[@"name"], equalTo(sut.name));
  assertThat(actual[@"path"], equalTo(sut.path));
  assertThat(actual[@"primaryArchitectureId"], equalTo(sut.primaryArchitectureId));
  assertThat(actual[@"architectureVariantId"], equalTo(sut.architectureVariantId));

}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  SNMBinary *sut = [self binary];

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([SNMBinary class]));
  
  SNMBinary *actualBinary = actual;
  assertThat(actualBinary.binaryId, equalTo(sut.binaryId));
  assertThat(actualBinary.startAddress, equalTo(sut.startAddress));
  assertThat(actualBinary.endAddress, equalTo(sut.endAddress));
  assertThat(actualBinary.name, equalTo(sut.name));
  assertThat(actualBinary.path, equalTo(sut.path));
  assertThat(actualBinary.primaryArchitectureId, equalTo(sut.primaryArchitectureId));
  assertThat(actualBinary.architectureVariantId, equalTo(sut.architectureVariantId));
}

#pragma mark - Helper

- (SNMBinary *)binary {
  NSString *binaryId = @"binaryId";
  NSString *startAddress = @"startAddress";
  NSString *endAddress = @"endAddress";
  NSString *name = @"name";
  NSString *path = @"path";
  NSNumber *primaryArchitectureId = @12;
  NSNumber *architectureVariantId = @23;
  
  SNMBinary *binary = [SNMBinary new];
  binary.binaryId = binaryId;
  binary.startAddress = startAddress;
  binary.endAddress = endAddress;
  binary.name = name;
  binary.path = path;
  binary.primaryArchitectureId = primaryArchitectureId;
  binary.architectureVariantId = architectureVariantId;
  
  return binary;
}

@end
