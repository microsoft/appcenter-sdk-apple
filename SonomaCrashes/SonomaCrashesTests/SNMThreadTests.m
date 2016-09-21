#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMThread.h"
#import "SNMException.h"
#import "SNMStackFrame.h"

@interface SNMThreadTests : XCTestCase

@end

@implementation SNMThreadTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  SNMThread *sut = [self thread];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"id"], equalTo(sut.threadId));
  assertThat(actual[@"name"], equalTo(sut.name));
  assertThat(actual[@"exception"], equalTo(sut.exception));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  // If
  SNMThread *sut = [self thread];
  
  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([SNMThread class]));
  
  SNMThread *actualThread = actual;
  assertThat(actualThread.threadId, equalTo(sut.threadId));
  assertThat(actualThread.name, equalTo(sut.name));
  assertThat(actualThread.exception.type, equalTo(sut.exception.type));
  assertThat(actualThread.exception.reason, equalTo(sut.exception.reason));
  assertThatUnsignedInt(actualThread.exception.frames.count, equalToUnsignedInteger(sut.exception.frames.count));

  assertThatInteger(actualThread.frames.count, equalToInteger(1));
}

#pragma mark - Helper

- (SNMThread *)thread {
  NSNumber *threadId = @(12);
  NSString *name = @"thread_name";
  
  SNMException *exception = [SNMException new];
  exception.type = @"exception_type";
  exception.reason = @"reason";
  SNMStackFrame *frame = [self stackFrame];
  exception.frames = [NSArray arrayWithObjects:frame, nil];
  
  SNMThread *thread = [SNMThread new];
  thread.threadId = threadId;
  thread.name = name;
  thread.exception = exception;
  thread.frames = [NSMutableArray arrayWithObject:frame];

  return thread;
}

- (SNMStackFrame *)stackFrame {
  NSString *address = @"address";
  NSString *code = @"code";
  
  SNMStackFrame *threadFrame = [SNMStackFrame new];
  threadFrame.address = address;
  threadFrame.code = code;
  
  return threadFrame;
}


@end
