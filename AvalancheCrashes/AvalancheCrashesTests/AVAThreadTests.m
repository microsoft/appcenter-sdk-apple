#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAAppleThread.h"
#import "AVAAppleStackFrame.h"

@interface AVAThreadTests : XCTestCase

@end

@implementation AVAThreadTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  AVAAppleThread *sut = [self thread];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"id"], equalTo(sut.threadId));
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
  assertThatInteger(actualThread.frames.count, equalToInteger(1));
}

#pragma mark - Helper

- (AVAAppleThread *)thread {
  NSNumber *threadId = @(12);
  NSArray<AVAAppleStackFrame *> *frames = [NSArray arrayWithObject:[AVAAppleStackFrame new]];
  
  AVAAppleThread *thread = [AVAAppleThread new];
  thread.threadId = threadId;
  thread.frames = [NSMutableArray arrayWithArray:frames];

  return thread;
}
@end
