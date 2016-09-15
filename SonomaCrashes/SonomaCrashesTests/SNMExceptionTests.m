#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMException.h"
#import "SNMStackFrame.h"

@interface SNMExceptionsTests : XCTestCase

@end

@implementation SNMExceptionsTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  SNMException *sut = [self exception];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"type"], equalTo(sut.type));
  assertThat(actual[@"reason"], equalTo(sut.reason));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  SNMException *sut = [self exception];
  
  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([SNMException class]));
  
  SNMException *actualException = actual;
  assertThat(actualException.type, equalTo(sut.type));
  assertThat(actualException.reason, equalTo(sut.reason));
  assertThatInteger(actualException.frames.count, equalToInteger(1));
  assertThat(actualException.frames.firstObject.address, equalTo(@"frameAddress"));
  assertThat(actualException.frames.firstObject.code, equalTo(@"frameSymbol"));
}

#pragma mark - Helper

- (SNMException *)exception {
  NSString *type = @"exception_type";
  NSString *reason = @"reason";
  SNMStackFrame *frame = [SNMStackFrame new];
  frame.address = @"frameAddress";
  frame.code = @"frameSymbol";
  NSArray<SNMStackFrame *>* frames = [NSArray arrayWithObject:frame];
  
  SNMException *exception = [SNMException new];
  exception.type = type;
  exception.reason = reason;
  exception.frames = frames;
  
  return exception;
}

@end
