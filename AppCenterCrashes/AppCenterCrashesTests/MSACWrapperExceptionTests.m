// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSACWrapperExceptionModel.h"
#import "MSACTestFrameworks.h"
#import "MSACWrapperExceptionInternal.h"
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

@interface MSACWrapperExceptionTests : XCTestCase

@property(nonatomic) MSACWrapperException *sut;

@end

@implementation MSACWrapperExceptionTests

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];
  self.sut = [self wrapperException];
  NSArray *allowedClassesArray = @[[MSACAppleErrorLog class], [NSDate class], [MSACDevice class], [MSACThread class], [MSACWrapperException class], [MSACAbstractErrorLog class], [MSACHandledErrorLog class], [MSACWrapperExceptionModel class], [MSACWrapperExceptionModel class], [MSACStackFrame class], [MSACBinary class], [MSACErrorAttachmentLog class], [MSACErrorReport class], [MSACWrapperSdk class], [NSUUID class], [NSDictionary class], [NSArray class], [NSNull class], [MSACThread class], [NSMutableData class], [MSACExceptionModel class]];
                
  [MSACUtility addAllowedClasses: allowedClassesArray];
}

#pragma mark - Helper

- (MSACWrapperException *)wrapperException {
  MSACWrapperException *exception = [MSACWrapperException new];
  exception.processId = @4;
  exception.exceptionData = [@"data string" dataUsingEncoding:NSUTF8StringEncoding];
  exception.modelException = [[MSACWrapperExceptionModel alloc] init];
  exception.modelException.type = @"type";
  exception.modelException.message = @"message";
  ((MSACWrapperExceptionModel *)exception.modelException).wrapperSdkName = @"wrapper sdk name";
  return exception;
}

#pragma mark - Tests

- (void)testInitializationWorks {
  XCTAssertNotNil(self.sut);
}

- (void)testSerializationToDictionaryWorks {
  NSDictionary *actual = [self.sut serializeToDictionary];
  XCTAssertNotNil(actual);
  assertThat(actual[@"processId"], equalTo(self.sut.processId));
  assertThat(actual[@"exceptionData"], equalTo(self.sut.exceptionData));

  // Exception fields.
  NSDictionary *exceptionDictionary = actual[@"modelException"];
  XCTAssertNotNil(exceptionDictionary);
  assertThat(exceptionDictionary[@"type"], equalTo(self.sut.modelException.type));
  assertThat(exceptionDictionary[@"message"], equalTo(self.sut.modelException.message));
  assertThat(exceptionDictionary[@"wrapperSdkName"], equalTo(((MSACWrapperExceptionModel *)self.sut.modelException).wrapperSdkName));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // When
  NSData *serializedWrapperException = [MSACUtility archiveKeyedData:self.sut];
  id actual = [MSACUtility unarchiveKeyedData:serializedWrapperException];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSACWrapperException class]));

  // The MSACAppleErrorLog.
  MSACWrapperException *actualWrapperException = actual;
  assertThat(actualWrapperException.processId, equalTo(self.sut.processId));
  assertThat(actualWrapperException.exceptionData, equalTo(self.sut.exceptionData));

  // The exception field.
  assertThat(actualWrapperException.modelException.type, equalTo(self.sut.modelException.type));
  assertThat(actualWrapperException.modelException.message, equalTo(((MSACWrapperExceptionModel *)self.sut.modelException.message)));
  assertThat(((MSACWrapperExceptionModel *)actualWrapperException.modelException).wrapperSdkName,
             equalTo(((MSACWrapperExceptionModel *)self.sut.modelException).wrapperSdkName));
}

@end
