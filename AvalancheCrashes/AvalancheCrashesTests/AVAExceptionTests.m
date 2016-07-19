#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAException.h"
#import "AVAThreadFrame.h"

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
  assertThat(actual[@"id"], equalTo(sut.exceptionId));
  assertThat(actual[@"reason"], equalTo(sut.reason));
  assertThat(actual[@"language"], equalTo(sut.language));
  assertThat(actual[@"frames"], equalTo(sut.frames));
  assertThat(actual[@"innerExceptions"], equalTo(sut.innerExceptions));
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
  assertThat(actualException.exceptionId, equalTo(sut.exceptionId));
  assertThat(actualException.reason, equalTo(sut.reason));
  assertThat(actualException.language, equalTo(sut.language));
  assertThatInteger(actualException.frames.count, equalToInteger(1));
  assertThatInteger(actualException.innerExceptions.count, equalToInteger(1));
}

#pragma mark - Helper

- (AVAException *)exception {
  NSNumber *exceptionId = @(12);
  NSString *reason = @"reason";
  NSString *language = @"language";
  NSArray<AVAThreadFrame *>* frames = [NSArray arrayWithObject:[AVAThreadFrame new]];
  NSArray<AVAException *>* innerExceptions = [NSArray arrayWithObject:[AVAException new]];
  
  AVAException *exception = [AVAException new];
  exception.exceptionId = exceptionId;
  exception.reason = reason;
  exception.language = language;
  exception.frames = frames;
  exception.innerExceptions = innerExceptions;
  
  return exception;
}

@end
