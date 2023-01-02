// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACCrashesTestUtil.h"
#import "MSACWrapperExceptionModel.h"
#import "MSACHandledErrorLog.h"
#import "MSACTestFrameworks.h"
#import "MSACExceptionModel.h"
#import "MSACStackFrame.h"
#import "MSACDevice.h"
#import "MSACErrorAttachmentLog+Utility.h"
#import "MSACErrorAttachmentLogInternal.h"
#import "MSACUtility.h"
#import "MSACAppleErrorLog.h"
#import "MSACBinary.h"
#import "MSACThread.h"
#import "MSACUserIdContext.h"
#import "MSACUtility+File.h"
#import "MSACWrapperCrashesHelper.h"
#import "MSACWrapperException.h"
#import "MSACErrorAttachmentLog.h"
#import "MSACErrorReport.h"

@interface MSACHandledErrorLogTests : XCTestCase

@property(nonatomic) MSACHandledErrorLog *sut;

@end

@implementation MSACHandledErrorLogTests

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];
  self.sut = [self handledErrorLog];
    NSArray *allowedClassesArray = @[[MSACAppleErrorLog class], [NSDate class], [MSACDevice class], [MSACThread class], [MSACWrapperException class], [MSACAbstractErrorLog class], [MSACHandledErrorLog class], [MSACWrapperExceptionModel class], [MSACStackFrame class], [MSACBinary class], [MSACErrorAttachmentLog class], [MSACErrorReport class], [MSACWrapperSdk class], [NSUUID class], [NSDictionary class], [NSArray class], [NSNull class], [NSMutableData class], [MSACExceptionModel class], [NSString class], [NSNumber class]];
              
    [MSACUtility addAllowedClasses: allowedClassesArray];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Helper

- (MSACHandledErrorLog *)handledErrorLog {
  MSACHandledErrorLog *handledErrorLog = [MSACHandledErrorLog new];
  handledErrorLog.type = @"handledError";
  handledErrorLog.exception = [MSACCrashesTestUtil exception];
  handledErrorLog.errorId = @"123";
  return handledErrorLog;
}

#pragma mark - Tests

- (void)testInitializationWorks {
  XCTAssertNotNil(self.sut);
}

- (void)testSerializationToDictionaryWorks {

  // When
  NSDictionary *actual = [self.sut serializeToDictionary];

  // Then
  XCTAssertNotNil(actual);
  assertThat(actual[@"type"], equalTo(self.sut.type));
  assertThat(actual[@"id"], equalTo(self.sut.errorId));
  NSDictionary *exceptionDictionary = actual[@"exception"];
  XCTAssertNotNil(exceptionDictionary);
  assertThat(exceptionDictionary[@"type"], equalTo(self.sut.exception.type));
  assertThat(exceptionDictionary[@"message"], equalTo(self.sut.exception.message));
  assertThat(exceptionDictionary[@"wrapperSdkName"], equalTo(((MSACWrapperExceptionModel *)self.sut.exception).wrapperSdkName));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // When
  NSData *serializedEvent = [MSACUtility archiveKeyedData:self.sut];
  id actual = [MSACUtility unarchiveKeyedData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSACHandledErrorLog class]));

  // The MSACHandledErrorLog.
  MSACHandledErrorLog *actualLog = actual;
  assertThat(actualLog, equalTo(self.sut));
  XCTAssertTrue([actualLog isEqual:self.sut]);
  assertThat(actualLog.type, equalTo(self.sut.type));
  assertThat(actualLog.errorId, equalTo(self.sut.errorId));

  // The exception field.
  MSACWrapperExceptionModel *actualException = actualLog.exception;
  assertThat(actualException.type, equalTo(self.sut.exception.type));
  assertThat(actualException.message, equalTo(self.sut.exception.message));
  assertThat(actualException.wrapperSdkName, equalTo(((MSACWrapperExceptionModel *)self.sut.exception).wrapperSdkName));
}

- (void)testIsEqual {

  // When
  MSACHandledErrorLog *first = [self handledErrorLog];
  MSACHandledErrorLog *second = [self handledErrorLog];

  // Then
  XCTAssertTrue([first isEqual:second]);

  // When
  second.errorId = MSAC_UUID_STRING;

  // Then
  XCTAssertFalse([first isEqual:second]);
}

- (void)testIsValid {

  // When
  MSACHandledErrorLog *log = [MSACHandledErrorLog new];
  log.device = OCMClassMock([MSACDevice class]);
  OCMStub([log.device isValid]).andReturn(YES);
  log.sid = @"sid";
  log.timestamp = [NSDate dateWithTimeIntervalSince1970:42];
  log.errorId = @"errorId";
  log.sid = MSAC_UUID_STRING;

  // Then
  XCTAssertFalse([log isValid]);

  // When
  log.errorId = MSAC_UUID_STRING;

  // Then
  XCTAssertFalse([log isValid]);

  // When
  log.exception = [MSACCrashesTestUtil exception];

  // Then
  XCTAssertTrue([log isValid]);
}

@end
