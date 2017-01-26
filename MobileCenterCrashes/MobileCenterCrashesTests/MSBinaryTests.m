#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSBinary.h"

@interface MSBinaryTests : XCTestCase

@end

@implementation MSBinaryTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  MSBinary *sut = [self binary];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"id"], equalTo(sut.binaryId));
  assertThat(actual[@"start_address"], equalTo(sut.startAddress));
  assertThat(actual[@"end_address"], equalTo(sut.endAddress));
  assertThat(actual[@"name"], equalTo(sut.name));
  assertThat(actual[@"path"], equalTo(sut.path));
  assertThat(actual[@"architecture"], equalTo(sut.architecture));
  assertThat(actual[@"primary_architecture_id"], equalTo(sut.primaryArchitectureId));
  assertThat(actual[@"architecture_variant_id"], equalTo(sut.architectureVariantId));

}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  MSBinary *sut = [self binary];

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSBinary class]));
  
  MSBinary *actualBinary = actual;
  assertThat(actualBinary, equalTo(actual));
  assertThat(actualBinary.binaryId, equalTo(sut.binaryId));
  assertThat(actualBinary.startAddress, equalTo(sut.startAddress));
  assertThat(actualBinary.endAddress, equalTo(sut.endAddress));
  assertThat(actualBinary.name, equalTo(sut.name));
  assertThat(actualBinary.path, equalTo(sut.path));
  assertThat(actualBinary.architecture, equalTo(sut.architecture));
  assertThat(actualBinary.primaryArchitectureId, equalTo(sut.primaryArchitectureId));
  assertThat(actualBinary.architectureVariantId, equalTo(sut.architectureVariantId));
}

#pragma mark - Helper

- (MSBinary *)binary {
  MSBinary *binary = [MSBinary new];
  binary.binaryId = @"binaryId";
  binary.startAddress = @"start_address";
  binary.endAddress = @"end_address";
  binary.name = @"name";
  binary.path = @"path";
  binary.architecture = @"architecture";
  binary.primaryArchitectureId = @12;
  binary.architectureVariantId = @23;
  
  return binary;
}

@end
