#import "MSAppleErrorLog.h"
#import "MSChannelDefault.h"
#import "MSCrashesDelegate.h"
#import "MSCrashesInternal.h"
#import "MSCrashesPrivate.h"
#import "MSCrashesTestUtil.h"
#import "MSCrashesUtil.h"
#import "MSCrashHandlerSetupDelegate.h"
#import "MSErrorAttachmentLogInternal.h"
#import "MSErrorLogFormatter.h"
#import "MSException.h"
#import "MSLogManagerDefault.h"
#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"
#import "MSMockCrashesDelegate.h"
#import "MSServiceAbstractPrivate.h"
#import "MSServiceAbstractProtected.h"
#import "MSTestFrameworks.h"
#import "MSWrapperExceptionManagerInternal.h"
#import "MSWrapperCrashesHelper.h"

@class MSMockCrashesDelegate;

static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSCrashesServiceName = @"Crashes";
static NSString *const kMSFatal = @"fatal";
static unsigned int kMaxAttachmentsPerCrashReport = 2;

@interface MSCrashes ()

+ (void)notifyWithUserConfirmation:(MSUserConfirmation)userConfirmation;

- (void)startCrashProcessing;

@end

@interface MSCrashesTests : XCTestCase <MSCrashesDelegate>

@property(nonatomic) MSCrashes *sut;

@end

@implementation MSCrashesTests

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSCrashes new];
}

- (void)tearDown {
  [super tearDown];
  [self.sut deleteAllFromCrashesDirectory];
  [MSCrashesTestUtil deleteAllFilesInDirectory:[self.sut.logBufferDir path]];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // When
  // An instance of MSCrashes is created.

  // Then
  assertThat(self.sut, notNilValue());
  assertThat(self.sut.fileManager, notNilValue());
  assertThat(self.sut.crashFiles, isEmpty());
  assertThat(self.sut.logBufferDir, notNilValue());
  assertThat(self.sut.crashesDir, notNilValue());
  assertThat(self.sut.analyzerInProgressFile, notNilValue());
  XCTAssertTrue(msCrashesLogBuffer.size() == ms_crashes_log_buffer_size);

  // Creation of buffer files is done asynchronously, we need to give it some time to create the files.
  [NSThread sleepForTimeInterval:0.05];
  NSError *error = [NSError errorWithDomain:@"MSTestingError" code:-57 userInfo:nil];
  NSArray *files = [[NSFileManager defaultManager]
      contentsOfDirectoryAtPath:reinterpret_cast<NSString *_Nonnull>([self.sut.logBufferDir path])
                          error:&error];
  assertThat(files, hasCountOf(ms_crashes_log_buffer_size));
}

- (void)testStartingManagerInitializesPLCrashReporter {

  // When
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Then
  assertThat(self.sut.plCrashReporter, notNilValue());
}

- (void)testStartingManagerWritesLastCrashReportToCrashesDir {
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());

  // When
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(1));
}

- (void)testSettingDelegateWorks {

  // When
  id<MSCrashesDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashesDelegate));
  [MSCrashes setDelegate:delegateMock];

  // Then
  id<MSCrashesDelegate> strongDelegate = [MSCrashes sharedInstance].delegate;
  XCTAssertNotNil(strongDelegate);
  XCTAssertEqual(strongDelegate, delegateMock);
}

- (void)testDelegateMethodsAreCalled {

  // If
  NSString *groupId = [[MSCrashes sharedInstance] groupId];
  id<MSCrashesDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashesDelegate));
  [MSMobileCenter sharedInstance].sdkConfigured = NO;
  [MSMobileCenter start:kMSTestAppSecret withServices:@[ [MSCrashes class] ]];
  NSMutableDictionary *channelsInLogManager =
      (static_cast<MSLogManagerDefault *>([MSCrashes sharedInstance].logManager)).channels;
  MSChannelDefault *channelMock = channelsInLogManager[groupId] = OCMPartialMock(channelsInLogManager[groupId]);
  OCMStub([channelMock enqueueItem:OCMOCK_ANY withCompletion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    id<MSLog> log = nil;
    [invocation getArgument:&log atIndex:2];
    for (id<MSChannelDelegate> delegate in channelMock.delegates) {

      // Call all channel delegate methods for testing.
      [delegate channel:channelMock willSendLog:log];
      [delegate channel:channelMock didSucceedSendingLog:log];
      [delegate channel:channelMock didFailSendingLog:log withError:nil];
    }
  });
  MSAppleErrorLog *errorLog = OCMClassMock([MSAppleErrorLog class]);
  MSErrorReport *errorReport = OCMClassMock([MSErrorReport class]);
  id errorLogFormatterMock = OCMClassMock([MSErrorLogFormatter class]);
  OCMStub(ClassMethod([errorLogFormatterMock errorReportFromLog:errorLog])).andReturn(errorReport);

  // When
  [[MSCrashes sharedInstance] setDelegate:delegateMock];
  [[MSCrashes sharedInstance].logManager processLog:errorLog forGroupId:groupId];

  // Then
  OCMVerify([delegateMock crashes:[MSCrashes sharedInstance] willSendErrorReport:errorReport]);
  OCMVerify([delegateMock crashes:[MSCrashes sharedInstance] didSucceedSendingErrorReport:errorReport]);
  OCMVerify([delegateMock crashes:[MSCrashes sharedInstance] didFailSendingErrorReport:errorReport withError:nil]);
}

- (void)testCrashHandlerSetupDelegateMethodsAreCalled {

  // If
  id<MSCrashHandlerSetupDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashHandlerSetupDelegate));
  [MSWrapperCrashesHelper setCrashHandlerSetupDelegate:delegateMock];

  // When
  [self.sut applyEnabledState:YES];

  // Then
  OCMVerify([delegateMock willSetUpCrashHandlers]);
  OCMVerify([delegateMock didSetUpCrashHandlers]);
  OCMVerify([delegateMock shouldEnableUncaughtExceptionHandler]);
}

- (void)testSettingUserConfirmationHandler {

  // When
  MSUserConfirmationHandler userConfirmationHandler =
      ^BOOL(__attribute__((unused)) NSArray<MSErrorReport *> *_Nonnull errorReports) {
        return NO;
      };
  [MSCrashes setUserConfirmationHandler:userConfirmationHandler];

  // Then
  XCTAssertNotNil([MSCrashes sharedInstance].userConfirmationHandler);
  XCTAssertEqual([MSCrashes sharedInstance].userConfirmationHandler, userConfirmationHandler);
}

- (void)testCrashesDelegateWithoutImplementations {

  // When
  MSMockCrashesDelegate *delegateMock = OCMPartialMock([MSMockCrashesDelegate new]);
  [MSCrashes setDelegate:delegateMock];

  // Then
  assertThatBool([[MSCrashes sharedInstance] shouldProcessErrorReport:nil], isTrue());
  assertThatBool([[MSCrashes sharedInstance] delegateImplementsAttachmentCallback], isFalse());
}

- (void)testProcessCrashes {

  // When
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [[MSCrashes sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Then
  assertThat([MSCrashes sharedInstance].crashFiles, hasCountOf(1));

  // When
  [MS_USER_DEFAULTS setObject:@YES forKey:@"MSUserConfirmation"];
  [[MSCrashes sharedInstance] startCrashProcessing];
  [MS_USER_DEFAULTS removeObjectForKey:@"MSUserConfirmation"];

  // Then
  assertThat([MSCrashes sharedInstance].crashFiles, hasCountOf(0));

  // When
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [[MSCrashes sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Then
  assertThat([MSCrashes sharedInstance].crashFiles, hasCountOf(1));

  // When
  MSUserConfirmationHandler userConfirmationHandlerYES =
      ^BOOL(__attribute__((unused)) NSArray<MSErrorReport *> *_Nonnull errorReports) {
        return YES;
      };
  [MSCrashes setUserConfirmationHandler:userConfirmationHandlerYES];
  [[MSCrashes sharedInstance] startCrashProcessing];
  [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
  [MSCrashes setUserConfirmationHandler:nil];

  // Then
  assertThat([MSCrashes sharedInstance].crashFiles, hasCountOf(0));

  // When
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [[MSCrashes sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Then
  assertThat([MSCrashes sharedInstance].crashFiles, hasCountOf(1));

  // When
  MSUserConfirmationHandler userConfirmationHandlerNO =
      ^BOOL(__attribute__((unused)) NSArray<MSErrorReport *> *_Nonnull errorReports) {
        return NO;
      };
  [MSCrashes setUserConfirmationHandler:userConfirmationHandlerNO];
  [[MSCrashes sharedInstance] startCrashProcessing];

  // Then
  assertThat([MSCrashes sharedInstance].crashFiles, hasCountOf(0));
}

- (void)testProcessCrashesWithErrorAttachments {
  
  // When
  id logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [[MSCrashes sharedInstance] startWithLogManager:logManagerMock appSecret:kMSTestAppSecret];
  NSString *validString = @"valid";
  NSData *validData = [validString dataUsingEncoding:NSUTF8StringEncoding];
  NSData *emptyData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
  NSArray *invalidLogs = @[
    [self attachmentWithAttachmentId:nil attachmentData:validData contentType:validString],
    [self attachmentWithAttachmentId:@"" attachmentData:validData contentType:validString],
    [self attachmentWithAttachmentId:validString attachmentData:nil contentType:validString],
    [self attachmentWithAttachmentId:validString attachmentData:emptyData contentType:validString],
    [self attachmentWithAttachmentId:validString attachmentData:validData contentType:nil],
    [self attachmentWithAttachmentId:validString attachmentData:validData contentType:@""]
  ];
  for(NSUInteger i = 0; i < invalidLogs.count; i++) {
    OCMReject([logManagerMock processLog:invalidLogs[i] forGroupId:OCMOCK_ANY]);
  }
  MSErrorAttachmentLog *validLog = [self attachmentWithAttachmentId:validString attachmentData:validData contentType:validString];
  NSMutableArray *logs = invalidLogs.mutableCopy;
  [logs addObject:validLog];
  id crashesDelegateMock = OCMProtocolMock(@protocol(MSCrashesDelegate));
  OCMStub([crashesDelegateMock attachmentsWithCrashes:OCMOCK_ANY forErrorReport:OCMOCK_ANY]).andReturn(logs);
  OCMStub([crashesDelegateMock crashes:OCMOCK_ANY shouldProcessErrorReport:OCMOCK_ANY]).andReturn(YES);
  [[MSCrashes sharedInstance] setDelegate:crashesDelegateMock];

  //Then
  OCMExpect([logManagerMock processLog:validLog forGroupId:OCMOCK_ANY]);
  [[MSCrashes sharedInstance] startCrashProcessing];
  OCMVerifyAll(logManagerMock);
}

- (void)testDeleteAllFromCrashesDirectory {

  // If
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_signal"], isTrue());
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // When
  [self.sut deleteAllFromCrashesDirectory];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(0));
}

- (void)testDeleteCrashReportsOnDisabled {

  // If
  id settingsMock = OCMClassMock([NSUserDefaults class]);
  OCMStub([settingsMock objectForKey:OCMOCK_ANY]).andReturn(@YES);
  self.sut.storage = settingsMock;
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];
  NSString *path = [self.sut.crashesDir path];

  // When
  [self.sut setEnabled:NO];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(0));
  assertThatLong([self.sut.fileManager contentsOfDirectoryAtPath:path error:nil].count, equalToLong(0));
}

- (void)testDeleteCrashReportsFromDisabledToEnabled {

  // If
  id settingsMock = OCMClassMock([NSUserDefaults class]);
  OCMStub([settingsMock objectForKey:OCMOCK_ANY]).andReturn(@NO);
  self.sut.storage = settingsMock;
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];
  NSString *path = [self.sut.crashesDir path];

  // When
  [self.sut setEnabled:YES];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(0));
  assertThatLong([self.sut.fileManager contentsOfDirectoryAtPath:path error:nil].count, equalToLong(0));
}

- (void)testSetupLogBufferWorks {

  // If
  // Creation of buffer files is done asynchronously, we need to give it some time to create the files.
  [NSThread sleepForTimeInterval:0.05];

  // Then
  NSError *error = [NSError errorWithDomain:@"MSTestingError" code:-57 userInfo:nil];
  NSArray *first = [[NSFileManager defaultManager]
      contentsOfDirectoryAtPath:reinterpret_cast<NSString *_Nonnull>([self.sut.logBufferDir path])
                          error:&error];
  XCTAssertTrue(first.count == ms_crashes_log_buffer_size);
  for (NSString *path in first) {
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    XCTAssertTrue(fileSize == 0);
  }

  // When
  [self.sut setupLogBuffer];

  // Then
  NSArray *second = [[NSFileManager defaultManager]
      contentsOfDirectoryAtPath:reinterpret_cast<NSString *_Nonnull>([self.sut.logBufferDir path])
                          error:&error];
  for (int i = 0; i < ms_crashes_log_buffer_size; i++) {
    XCTAssertTrue([first[i] isEqualToString:second[i]]);
  }
}

- (void)testCreateBufferFile {
  // When
  NSString *testName = @"afilename";
  NSString *filePath = [[self.sut.logBufferDir path]
      stringByAppendingPathComponent:[testName stringByAppendingString:@".mscrasheslogbuffer"]];
  [self.sut createBufferFileAtURL:[NSURL fileURLWithPath:filePath]];

  // Then
  BOOL success = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
  XCTAssertTrue(success);
}

- (void)testEmptyLogBufferFiles {
  // If
  NSString *testName = @"afilename";
  NSString *dataString = @"SomeBufferedData";
  NSData *someData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
  NSString *filePath = [[self.sut.logBufferDir path]
      stringByAppendingPathComponent:[testName stringByAppendingString:@".mscrasheslogbuffer"]];

#if TARGET_OS_OSX
  [someData writeToFile:filePath atomically:YES];
#else
  [someData writeToFile:filePath options:NSDataWritingFileProtectionNone error:nil];
#endif

  // When
  BOOL success = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
  XCTAssertTrue(success);

  // Then
  unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
  XCTAssertTrue(fileSize == 16);
  [self.sut emptyLogBufferFiles];
  fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
  XCTAssertTrue(fileSize == 0);
}

- (void)testBufferIndexIncrementForAllPriorities {

  // When
  MSLogWithProperties *log = [MSLogWithProperties new];
  [self.sut onEnqueuingLog:log withInternalId:MS_UUID_STRING];

  // Then
  XCTAssertTrue([self crashesLogBufferCount] == 1);
}

- (void)testBufferIndexOverflowForAllPriorities {

  // When
  for (int i = 0; i < ms_crashes_log_buffer_size; i++) {
    MSLogWithProperties *log = [MSLogWithProperties new];
    [self.sut onEnqueuingLog:log withInternalId:MS_UUID_STRING];
  }

  // Then
  XCTAssertTrue([self crashesLogBufferCount] == ms_crashes_log_buffer_size);

  // When
  MSLogWithProperties *log = [MSLogWithProperties new];
  [self.sut onEnqueuingLog:log withInternalId:MS_UUID_STRING];
  NSNumberFormatter *timestampFormatter = [[NSNumberFormatter alloc] init];
  timestampFormatter.numberStyle = NSNumberFormatterDecimalStyle;
  int indexOfLatestObject = 0;
  NSNumber *oldestTimestamp;
  for (auto it = msCrashesLogBuffer.begin(), end = msCrashesLogBuffer.end(); it != end; ++it) {
    NSString *timestampString = [NSString stringWithCString:it->timestamp.c_str() encoding:NSUTF8StringEncoding];
    NSNumber *bufferedLogTimestamp = [timestampFormatter numberFromString:timestampString];

    // Remember the timestamp if the log is older than the previous one or the initial one.
    if (!oldestTimestamp || oldestTimestamp.doubleValue > bufferedLogTimestamp.doubleValue) {
      oldestTimestamp = bufferedLogTimestamp;
      indexOfLatestObject = static_cast<int>(it - msCrashesLogBuffer.begin());
    }
  }
  // Then
  XCTAssertTrue([self crashesLogBufferCount] == ms_crashes_log_buffer_size);
  XCTAssertTrue(indexOfLatestObject == 1);

  // If
  int numberOfLogs = 50;
  // When
  for (int i = 0; i < numberOfLogs; i++) {
    MSLogWithProperties *aLog = [MSLogWithProperties new];
    [self.sut onEnqueuingLog:aLog withInternalId:MS_UUID_STRING];
  }

  indexOfLatestObject = 0;
  oldestTimestamp = nil;
  for (auto it = msCrashesLogBuffer.begin(), end = msCrashesLogBuffer.end(); it != end; ++it) {
    NSString *timestampString = [NSString stringWithCString:it->timestamp.c_str() encoding:NSUTF8StringEncoding];
    NSNumber *bufferedLogTimestamp = [timestampFormatter numberFromString:timestampString];

    // Remember the timestamp if the log is older than the previous one or the initial one.
    if (!oldestTimestamp || oldestTimestamp.doubleValue > bufferedLogTimestamp.doubleValue) {
      oldestTimestamp = bufferedLogTimestamp;
      indexOfLatestObject = static_cast<int>(it - msCrashesLogBuffer.begin());
    }
  }

  // Then
  XCTAssertTrue([self crashesLogBufferCount] == ms_crashes_log_buffer_size);
  XCTAssertTrue(indexOfLatestObject == (1 + (numberOfLogs % ms_crashes_log_buffer_size)));
}

- (void)testBufferIndexOnPersistingLog {

  // When
  MSLogWithProperties *log = [MSLogWithProperties new];
  NSString *uuid1 = MS_UUID_STRING;
  NSString *uuid2 = MS_UUID_STRING;
  NSString *uuid3 = MS_UUID_STRING;
  [self.sut onEnqueuingLog:log withInternalId:uuid1];
  [self.sut onEnqueuingLog:log withInternalId:uuid2];
  [self.sut onEnqueuingLog:log withInternalId:uuid3];

  // Then
  XCTAssertTrue([self crashesLogBufferCount] == 3);

  // When
  [self.sut onFinishedPersistingLog:nil withInternalId:uuid1];

  // Then
  XCTAssertTrue([self crashesLogBufferCount] == 2);

  // When
  [self.sut onFailedPersistingLog:nil withInternalId:uuid2];

  // Then
  XCTAssertTrue([self crashesLogBufferCount] == 1);
}

- (void)testInitializationPriorityCorrect {
  XCTAssertTrue([[MSCrashes sharedInstance] initializationPriority] == MSInitializationPriorityMax);
}

- (void)testDisableMachExceptionWorks {

  // Then
  XCTAssertTrue([[MSCrashes sharedInstance] isMachExceptionHandlerEnabled]);

  // When
  [MSCrashes disableMachExceptionHandler];

  // Then
  XCTAssertFalse([[MSCrashes sharedInstance] isMachExceptionHandlerEnabled]);

  // Then
  XCTAssertTrue([self.sut isMachExceptionHandlerEnabled]);

  // When
  [self.sut setEnableMachExceptionHandler:NO];

  // Then
  XCTAssertFalse([self.sut isMachExceptionHandlerEnabled]);
}

- (void)testAbstractErrorLogSerialization {
  MSAbstractErrorLog *log = [MSAbstractErrorLog new];

  // When
  NSDictionary *serializedLog = [log serializeToDictionary];

  // Then
  XCTAssertFalse([static_cast<NSNumber *>([serializedLog objectForKey:kMSFatal]) boolValue]);

  // If
  log.fatal = NO;

  // When
  serializedLog = [log serializeToDictionary];

  // Then
  XCTAssertFalse([static_cast<NSNumber *>([serializedLog objectForKey:kMSFatal]) boolValue]);

  // If
  log.fatal = YES;

  // When
  serializedLog = [log serializeToDictionary];

  // Then
  XCTAssertTrue([static_cast<NSNumber *>([serializedLog objectForKey:kMSFatal]) boolValue]);
}

- (void)testWarningMessageAboutTooManyErrorAttachments {

  NSString *expectedMessage = [NSString stringWithFormat:@"A limit of %u attachments per error report might be enforced by server.", kMaxAttachmentsPerCrashReport];
  __block bool warningMessageHasBeenPrinted = false;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"
  [MSLogger setLogHandler:^(MSLogMessageProvider messageProvider, MSLogLevel logLevel, NSString *tag, const char *file,
                            const char *function, uint line) {
    if(warningMessageHasBeenPrinted) {
      return;
    }
    NSString *message = messageProvider();
    warningMessageHasBeenPrinted = [message isEqualToString:expectedMessage];
  }];
#pragma clang diagnostic pop

  // When
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [[MSCrashes sharedInstance] setDelegate:self];
  [[MSCrashes sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];
  [[MSCrashes sharedInstance] startCrashProcessing];

  XCTAssertTrue(warningMessageHasBeenPrinted);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"
- (NSArray<MSErrorAttachmentLog *> *)attachmentsWithCrashes:(MSCrashes *)crashes forErrorReport:(MSErrorReport *)errorReport {
  id deviceMock = OCMPartialMock([MSDevice new]);
  OCMStub([deviceMock isValid]).andReturn(YES);

  NSMutableArray *logs = [NSMutableArray new];
  for(unsigned int i = 0; i < kMaxAttachmentsPerCrashReport + 1; ++i) {
    NSString *text = [NSString stringWithFormat:@"%d", i];
    MSErrorAttachmentLog *log = [[MSErrorAttachmentLog alloc] initWithFilename:text attachmentText:text];
    log.toffset = [NSNumber numberWithInt:0];
    log.device = deviceMock;
    [logs addObject:log];
  }
  return logs;
}
#pragma clang diagnostic pop

- (NSInteger)crashesLogBufferCount {
  NSInteger bufferCount = 0;
  for (auto it = msCrashesLogBuffer.begin(), end = msCrashesLogBuffer.end(); it != end; ++it) {
    if (!it->internalId.empty()) {
      bufferCount++;
    }
  }
  return bufferCount;
}

- (MSErrorAttachmentLog *)attachmentWithAttachmentId:(NSString *)attachmentId
                                      attachmentData:(NSData *)attachmentData
                                         contentType:(NSString *)contentType {
  MSErrorAttachmentLog *log = [MSErrorAttachmentLog alloc];
  log.attachmentId = attachmentId;
  log.data = attachmentData;
  log.contentType = contentType;
  return log;
}

@end
