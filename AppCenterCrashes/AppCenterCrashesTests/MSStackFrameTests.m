// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSStackFrame.h"
#import "MSTestFrameworks.h"

@interface MSStackFrameTests : XCTestCase

@end

@implementation MSStackFrameTests

#pragma mark - Helper

- (MSStackFrame *)stackFrame {
  NSString *address = @"address";
  NSString *code = @"code";
  NSString *className = @"class_name";
  NSString *methodName = @"method_name";
  NSNumber *lineNumber = @123;
  NSString *fileName = @"file_name";

  MSStackFrame *threadFrame = [MSStackFrame new];
  threadFrame.address = address;
  threadFrame.code = code;
  threadFrame.className = className;
  threadFrame.methodName = methodName;
  threadFrame.lineNumber = lineNumber;
  threadFrame.fileName = fileName;

  return threadFrame;
}

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
  assertThat(actual[@"className"], equalTo(sut.className));
  assertThat(actual[@"methodName"], equalTo(sut.methodName));
  assertThat(actual[@"lineNumber"], equalTo(sut.lineNumber));
  assertThat(actual[@"fileName"], equalTo(sut.fileName));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  MSStackFrame *sut = [self stackFrame];

  // When
  NSData *serializedEvent = [MSUtility archiveKeyedData:sut];
  id actual = [MSUtility unarchiveKeyedData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSStackFrame class]));

  MSStackFrame *actualThreadFrame = actual;
  assertThat(actualThreadFrame, equalTo(sut));
  assertThat(actualThreadFrame.address, equalTo(sut.address));
  assertThat(actualThreadFrame.code, equalTo(sut.code));
  assertThat(actualThreadFrame.className, equalTo(sut.className));
  assertThat(actualThreadFrame.methodName, equalTo(sut.methodName));
  assertThat(actualThreadFrame.lineNumber, equalTo(sut.lineNumber));
  assertThat(actualThreadFrame.fileName, equalTo(sut.fileName));
}

- (void)testIsNotEqualToNil {

  // Then
  XCTAssertFalse([[MSStackFrame new] isEqual:nil]);
}

@end
