// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSACStackFrame.h"
#import "MSACTestFrameworks.h"

#import "MSACWrapperExceptionModel.h"
#import "MSACHandledErrorLog.h"
#import "MSACExceptionModel.h"
#import "MSACStackFrame.h"
#import "MSACDevice.h"
#import "MSACUtility.h"
#import "MSACAppleErrorLog.h"
#import "MSACBinary.h"
#import "MSACThread.h"
#import "MSACWrapperException.h"
#import "MSACErrorAttachmentLog.h"
#import "MSACErrorReport.h"

@interface MSACStackFrameTests : XCTestCase

@end

@implementation MSACStackFrameTests

- (void)setUp {
  [super setUp];
  NSArray *allowedClassesArray = @[[MSACAppleErrorLog class], [NSDate class], [MSACDevice class], [MSACThread class], [MSACWrapperException class], [MSACAbstractErrorLog class], [MSACHandledErrorLog class], [MSACWrapperExceptionModel class], [MSACStackFrame class], [MSACBinary class], [MSACErrorAttachmentLog class], [MSACErrorReport class], [MSACWrapperSdk class], [NSUUID class], [NSDictionary class], [NSArray class], [NSNull class], [NSMutableData class], [MSACExceptionModel class], [NSString class], [NSNumber class]];
              
  [MSACUtility addAllowedClasses: allowedClassesArray];
}

#pragma mark - Helper

- (MSACStackFrame *)stackFrame {
  NSString *address = @"address";
  NSString *code = @"code";
  NSString *className = @"class_name";
  NSString *methodName = @"method_name";
  NSNumber *lineNumber = @123;
  NSString *fileName = @"file_name";

  MSACStackFrame *threadFrame = [MSACStackFrame new];
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
  MSACStackFrame *sut = [self stackFrame];

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
  MSACStackFrame *sut = [self stackFrame];

  // When
  NSData *serializedEvent = [MSACUtility archiveKeyedData:sut];
  id actual = [MSACUtility unarchiveKeyedData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSACStackFrame class]));

  MSACStackFrame *actualThreadFrame = actual;
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
  XCTAssertFalse([[MSACStackFrame new] isEqual:nil]);
}

@end
