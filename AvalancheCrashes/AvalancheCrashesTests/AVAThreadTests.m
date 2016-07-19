#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAThread.h"
#import "AVAThreadFrame.h"

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
  assertThat(actual[@"frames"], equalTo(sut.frames));
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
  assertThatInteger(actualThread.frames.count, equalToInteger(1));
}

#pragma mark - Helper

- (AVAThread *)thread {
  NSNumber *threadId = @(12);
  NSArray<AVAThreadFrame *> *frames = [NSArray arrayWithObject:[AVAThreadFrame new]];
  
  AVAThread *thread = [AVAThread new];
  thread.threadId = threadId;
  thread.frames = frames;

  return thread;
}
@end
