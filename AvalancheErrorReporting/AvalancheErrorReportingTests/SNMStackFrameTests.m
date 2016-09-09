#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMStackFrame.h"

@interface SNMStackFrameTests : XCTestCase

@end

@implementation SNMStackFrameTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  SNMStackFrame *sut = [self stackFrame];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"address"], equalTo(sut.address));
  assertThat(actual[@"code"], equalTo(sut.code));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  SNMStackFrame *sut = [self stackFrame];
  
  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([SNMStackFrame class]));
  
  SNMStackFrame *actualThreadFrame = actual;
  assertThat(actualThreadFrame.address, equalTo(sut.address));
  assertThat(actualThreadFrame.code, equalTo(sut.code));
}

#pragma mark - Helper

- (SNMStackFrame *)stackFrame {
  NSString *address = @"address";
  NSString *code = @"code";
  
  SNMStackFrame *threadFrame = [SNMStackFrame new];
  threadFrame.address = address;
  threadFrame.code = code;
  
  return threadFrame;
}

@end
