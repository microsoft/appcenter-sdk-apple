#import "MSException.h"
#import "MSStackFrame.h"
#import "MSTestFrameworks.h"
#import "MSThread.h"

@interface MSThreadTests : XCTestCase

@end

@implementation MSThreadTests

#pragma mark - Helper

- (MSThread *)thread {
  NSNumber *threadId = @(12);
  NSString *name = @"thread_name";

  MSException *exception = [MSException new];
  exception.type = @"exception_type";
  exception.message = @"message";
  MSStackFrame *frame = [self stackFrame];
  exception.frames = @[ frame ];

  MSThread *thread = [MSThread new];
  thread.threadId = threadId;
  thread.name = name;
  thread.exception = exception;
  thread.frames = [@[ frame ] mutableCopy];

  return thread;
}

- (MSStackFrame *)stackFrame {
  NSString *address = @"address";
  NSString *code = @"code";

  MSStackFrame *threadFrame = [MSStackFrame new];
  threadFrame.address = address;
  threadFrame.code = code;

  return threadFrame;
}

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {

  // If
  MSThread *sut = [self thread];

  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"id"], equalTo(sut.threadId));
  assertThat(actual[@"name"], equalTo(sut.name));
  assertThat([actual[@"exception"] valueForKey:@"type"], equalTo(sut.exception.type));
  assertThat([actual[@"exception"] valueForKey:@"message"], equalTo(sut.exception.message));

  NSArray *actualFrames = [actual[@"exception"] valueForKey:@"frames"];
  XCTAssertEqual(actualFrames.count, sut.exception.frames.count);
  NSDictionary *actualFrame = [actualFrames firstObject];
  MSStackFrame *expectedFrame = [sut.exception.frames firstObject];
  assertThat([actualFrame valueForKey:@"code"], equalTo(expectedFrame.code));
  assertThat([actualFrame valueForKey:@"address"], equalTo(expectedFrame.address));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  // If
  MSThread *sut = [self thread];

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSThread class]));

  MSThread *actualThread = actual;
  assertThat(actualThread, equalTo(actual));
  assertThat(actualThread.threadId, equalTo(sut.threadId));
  assertThat(actualThread.name, equalTo(sut.name));
  assertThat(actualThread.exception.type, equalTo(sut.exception.type));
  assertThat(actualThread.exception.message, equalTo(sut.exception.message));
  assertThatUnsignedLong(actualThread.exception.frames.count, equalToUnsignedLong(sut.exception.frames.count));

  assertThatInteger(actualThread.frames.count, equalToInteger(1));
}

- (void)testIsValid {

  // When
  MSThread *thread = [MSThread new];

  // Then
  XCTAssertFalse([thread isValid]);

  // When
  thread.threadId = @123;

  // Then
  XCTAssertFalse([thread isValid]);

  // When
  [thread.frames addObject:[MSStackFrame new]];

  // Then
  XCTAssertTrue([thread isValid]);
}

- (void)testIsNotEqualToNil {

  // Then
  XCTAssertFalse([[MSThread new] isEqual:nil]);
}

@end
