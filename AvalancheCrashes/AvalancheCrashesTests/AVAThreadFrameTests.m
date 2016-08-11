#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAThreadFrame.h"

@interface AVAThreadFrameTests : XCTestCase

@end

@implementation AVAThreadFrameTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  AVAThreadFrame *sut = [self threadFrame];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"address"], equalTo(sut.address));
  assertThat(actual[@"symbol"], equalTo(sut.symbol));
  assertThat(actual[@"registers"], equalTo(sut.registers));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  AVAThreadFrame *sut = [self threadFrame];
  
  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([AVAThreadFrame class]));
  
  AVAThreadFrame *actualThreadFrame = actual;
  assertThat(actualThreadFrame.address, equalTo(sut.address));
  assertThat(actualThreadFrame.symbol, equalTo(sut.symbol));
  assertThat(actualThreadFrame.registers, equalTo(sut.registers));
}

#pragma mark - Helper

- (AVAThreadFrame *)threadFrame {
  NSString *address = @"address";
  NSString *symbol = @"symbol";
  NSDictionary<NSString*, NSString*>* registers = [NSDictionary dictionaryWithObject:@"Value" forKey:@"Key"];
  
  AVAThreadFrame *threadFrame = [AVAThreadFrame new];
  threadFrame.address = address;
  threadFrame.symbol = symbol;
  threadFrame.registers = registers;
  
  return threadFrame;
}

@end
