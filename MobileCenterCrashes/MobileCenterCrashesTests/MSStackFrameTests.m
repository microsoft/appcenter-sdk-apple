#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSStackFrame.h"

@interface MSStackFrameTests : XCTestCase

@end

@implementation MSStackFrameTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  MSStackFrame *sut = [self stackFrame];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"address"], equalTo(sut.address));
  assertThat(actual[@"code"], equalTo(sut.code));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  MSStackFrame *sut = [self stackFrame];
  
  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSStackFrame class]));
  
  MSStackFrame *actualThreadFrame = actual;
  assertThat(actualThreadFrame.address, equalTo(sut.address));
  assertThat(actualThreadFrame.code, equalTo(sut.code));
}

#pragma mark - Helper

- (MSStackFrame *)stackFrame {
  NSString *address = @"address";
  NSString *code = @"code";
  
  MSStackFrame *threadFrame = [MSStackFrame new];
  threadFrame.address = address;
  threadFrame.code = code;
  
  return threadFrame;
}

@end
