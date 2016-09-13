#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAStackFrame.h"

@interface AVAStackFrameTests : XCTestCase

@end

@implementation AVAStackFrameTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  AVAStackFrame *sut = [self stackFrame];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"address"], equalTo(sut.address));
  assertThat(actual[@"code"], equalTo(sut.code));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  AVAStackFrame *sut = [self stackFrame];
  
  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([AVAStackFrame class]));
  
  AVAStackFrame *actualThreadFrame = actual;
  assertThat(actualThreadFrame.address, equalTo(sut.address));
  assertThat(actualThreadFrame.code, equalTo(sut.code));
}

#pragma mark - Helper

- (AVAStackFrame *)stackFrame {
  NSString *address = @"address";
  NSString *code = @"code";
  
  AVAStackFrame *threadFrame = [AVAStackFrame new];
  threadFrame.address = address;
  threadFrame.code = code;
  
  return threadFrame;
}

@end
