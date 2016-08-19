#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAAppleThread.h"
#import "AVAAppleException.h"
#import "AVAAppleStackFrame.h"

@interface AVAAppleThreadTests : XCTestCase

@end

@implementation AVAAppleThreadTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  AVAAppleThread *sut = [self thread];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"id"], equalTo(sut.threadId));
  assertThat(actual[@"name"], equalTo(sut.name));
  assertThat(actual[@"lastException"], equalTo(sut.lastException));
  assertThat(actual[@"frames"], equalTo(sut.frames));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  // If
  AVAAppleThread *sut = [self thread];
  
  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([AVAAppleThread class]));
  
  AVAAppleThread *actualThread = actual;
  assertThat(actualThread.threadId, equalTo(sut.threadId));
  assertThat(actualThread.name, equalTo(sut.name));
  assertThat(actualThread.lastException.type, equalTo(sut.lastException.type));
  assertThat(actualThread.lastException.reason, equalTo(sut.lastException.reason));
  assertThatUnsignedInt(actualThread.lastException.frames.count, equalToUnsignedInteger(sut.lastException.frames.count));

  assertThatInteger(actualThread.frames.count, equalToInteger(1));
}

#pragma mark - Helper

- (AVAAppleThread *)thread {
  NSNumber *threadId = @(12);
  NSString *name = @"threadName";
  
  AVAAppleException *exception = [AVAAppleException new];
  exception.type = @"exceptionType";
  exception.reason = @"reason";
  exception.frames = [NSArray arrayWithObject:[AVAAppleStackFrame new]];

  NSArray<AVAAppleStackFrame *> *frames = [NSArray arrayWithObject:[AVAAppleStackFrame new]];
  
  AVAAppleThread *thread = [AVAAppleThread new];
  thread.threadId = threadId;
  thread.name = name;
  thread.lastException = exception;
  thread.frames = [NSMutableArray arrayWithArray:frames];

  return thread;
}
@end
