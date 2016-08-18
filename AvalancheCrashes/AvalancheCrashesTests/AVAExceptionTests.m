#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAAppleException.h"
#import "AVAThreadFrame.h"

@interface AVAExceptionsTests : XCTestCase

@end

@implementation AVAExceptionsTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  AVAAppleException *sut = [self exception];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"type"], equalTo(sut.type));
  assertThat(actual[@"reason"], equalTo(sut.reason));
  assertThat(actual[@"frames"], equalTo(sut.frames));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  AVAAppleException *sut = [self exception];
  
  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([AVAAppleException class]));
  
  AVAAppleException *actualException = actual;
  assertThat(actualException.type, equalTo(sut.type));
  assertThat(actualException.reason, equalTo(sut.reason));
  assertThatInteger(actualException.frames.count, equalToInteger(1));
}

#pragma mark - Helper

- (AVAAppleException *)exception {
  NSString *type = @"exceptionType";
  NSString *reason = @"reason";
  NSArray<AVAThreadFrame *>* frames = [NSArray arrayWithObject:[AVAThreadFrame new]];
  
  AVAAppleException *exception = [AVAAppleException new];
  exception.type = type;
  exception.reason = reason;
  exception.frames = frames;
  
  return exception;
}

@end
