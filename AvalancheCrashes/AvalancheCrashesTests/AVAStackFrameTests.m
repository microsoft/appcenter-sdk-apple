#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAAppleStackFrame.h"

@interface AVAAppleStackFrameTests : XCTestCase

@end

@implementation AVAAppleStackFrameTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  AVAAppleStackFrame *sut = [self stackFrame];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"address"], equalTo(sut.address));
  assertThat(actual[@"symbol"], equalTo(sut.symbol));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  AVAAppleStackFrame *sut = [self stackFrame];
  
  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([AVAAppleStackFrame class]));
  
  AVAAppleStackFrame *actualThreadFrame = actual;
  assertThat(actualThreadFrame.address, equalTo(sut.address));
  assertThat(actualThreadFrame.symbol, equalTo(sut.symbol));
}

#pragma mark - Helper

- (AVAAppleStackFrame *)stackFrame {
  NSString *address = @"address";
  NSString *symbol = @"symbol";
  
  AVAAppleStackFrame *threadFrame = [AVAAppleStackFrame new];
  threadFrame.address = address;
  threadFrame.symbol = symbol;
  
  return threadFrame;
}

@end
