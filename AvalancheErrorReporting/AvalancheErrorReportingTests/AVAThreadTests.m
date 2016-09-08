#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAThread.h"
#import "AVAException.h"
#import "AVAStackFrame.h"

@interface AVAThreadTests : XCTestCase

@end

@implementation AVAThreadTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  AVAThread *sut = [self thread];
  
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
  AVAThread *sut = [self thread];
  
  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([AVAThread class]));
  
  AVAThread *actualThread = actual;
  assertThat(actualThread.threadId, equalTo(sut.threadId));
  assertThat(actualThread.name, equalTo(sut.name));
  assertThat(actualThread.exception.type, equalTo(sut.exception.type));
  assertThat(actualThread.exception.reason, equalTo(sut.exception.reason));
  assertThatUnsignedInt(actualThread.exception.frames.count, equalToUnsignedInteger(sut.exception.frames.count));

  assertThatInteger(actualThread.frames.count, equalToInteger(1));
}

#pragma mark - Helper

- (AVAThread *)thread {
  NSNumber *threadId = @(12);
  NSString *name = @"threadName";
  
  AVAException *exception = [AVAException new];
  exception.type = @"exceptionType";
  exception.reason = @"reason";
  AVAStackFrame *frame = [self stackFrame];
  exception.frames = [NSArray arrayWithObjects:frame, nil];
  
  AVAThread *thread = [AVAThread new];
  thread.threadId = threadId;
  thread.name = name;
  thread.exception = exception;
  thread.frames = [NSMutableArray arrayWithObject:frame];

  return thread;
}

- (AVAStackFrame *)stackFrame {
  NSString *address = @"address";
  NSString *code = @"code";
  
  AVAStackFrame *threadFrame = [AVAStackFrame new];
  threadFrame.address = address;
  threadFrame.code = code;
  
  return threadFrame;
}


@end
