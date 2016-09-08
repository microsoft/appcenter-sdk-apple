#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAException.h"
#import "AVAStackFrame.h"

@interface AVAExceptionsTests : XCTestCase

@end

@implementation AVAExceptionsTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  AVAException *sut = [self exception];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"type"], equalTo(sut.type));
  assertThat(actual[@"reason"], equalTo(sut.reason));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  AVAException *sut = [self exception];
  
  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([AVAException class]));
  
  AVAException *actualException = actual;
  assertThat(actualException.type, equalTo(sut.type));
  assertThat(actualException.reason, equalTo(sut.reason));
  assertThatInteger(actualException.frames.count, equalToInteger(1));
  assertThat(actualException.frames.firstObject.address, equalTo(@"frameAddress"));
  assertThat(actualException.frames.firstObject.code, equalTo(@"frameSymbol"));
}

#pragma mark - Helper

- (AVAException *)exception {
  NSString *type = @"exceptionType";
  NSString *reason = @"reason";
  AVAStackFrame *frame = [AVAStackFrame new];
  frame.address = @"frameAddress";
  frame.code = @"frameSymbol";
  NSArray<AVAStackFrame *>* frames = [NSArray arrayWithObject:frame];
  
  AVAException *exception = [AVAException new];
  exception.type = type;
  exception.reason = reason;
  exception.frames = frames;
  
  return exception;
}

@end
