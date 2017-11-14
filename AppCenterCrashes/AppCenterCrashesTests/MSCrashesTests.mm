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
#import "MSHandledErrorLog.h"
#import "MSLogManagerDefault.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
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
static NSString *const kMSTypeHandledError = @"handled_error";
static NSString *const kMSUserConfirmationKey = @"MSUserConfirmation";
static unsigned int kMaxAttachmentsPerCrashReport = 2;

@interface MSCrashes ()

+ (void)notifyWithUserConfirmation:(MSUserConfirmation)userConfirmation;
- (void)startCrashProcessing;
- (void)shouldAlwaysSend;
- (void)emptyLogBufferFiles;

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
  [MSCrashesTestUtil deleteAllFilesInDirectory:[[self.sut logBufferDir] path]];
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
  [MSAppCenter sharedInstance].sdkConfigured = NO;
  [MSAppCenter start:kMSTestAppSecret withServices:@[ [MSCrashes class] ]];
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
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(1));

  // When
  OCMStub([self.sut shouldAlwaysSend]).andReturn(YES);
  [self.sut startCrashProcessing];
  OCMStub([self.sut shouldAlwaysSend]).andReturn(NO);

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(0));

  // When
  self.sut = [MSCrashes new];
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(1));

  // When
  self.sut = [MSCrashes new];
  MSUserConfirmationHandler userConfirmationHandlerYES =
  ^BOOL(__attribute__((unused)) NSArray<MSErrorReport *> *_Nonnull errorReports) {
    return YES;
  };

  self.sut.userConfirmationHandler = userConfirmationHandlerYES;
  [self.sut startCrashProcessing];
  [self.sut notifyWithUserConfirmation:MSUserConfirmationDontSend];
  self.sut.userConfirmationHandler = nil;

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(0));

  // When
  self.sut = [MSCrashes new];
  assertThatBool([MSCrashesTestUtil copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  [self.sut startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(1));

  // When
  self.sut = [MSCrashes new];
  MSUserConfirmationHandler userConfirmationHandlerNO =
  ^BOOL(__attribute__((unused)) NSArray<MSErrorReport *> *_Nonnull errorReports) {
    return NO;
  };
  self.sut.userConfirmationHandler = userConfirmationHandlerNO;
  [self.sut startCrashProcessing];

  // Then
  assertThat(self.sut.crashFiles, hasCountOf(0));
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

// The Mach exception handler is not supported on tvOS.
#if TARGET_OS_TV
- (void) testMachExceptionHandlerDisabledOnTvOS {

  // Then
  XCTAssertFalse([[MSCrashes sharedInstance] isMachExceptionHandlerEnabled]);
}
#else
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

#endif

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

- (void)testTrackModelException {

  // If
  __block NSString *type;
  __block NSString *errorId;
  __block MSException *exception;
  id<MSLogManager> logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  OCMStub([logManagerMock processLog:[OCMArg isKindOfClass:[MSAbstractLog class]] forGroupId:OCMOCK_ANY])
  .andDo(^(NSInvocation *invocation) {
    MSHandledErrorLog *log;
    [invocation getArgument:&log atIndex:2];
    type = log.type;
    errorId = log.errorId;
    exception = log.exception;
  });
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [self.sut startWithLogManager:logManagerMock appSecret:kMSTestAppSecret];

  // When
  MSException *expectedException = [MSException new];
  expectedException.message = @"Oh this is wrong...";
  expectedException.stackTrace = @"mock strace";
  expectedException.type = @"Some.Exception";
  [self.sut trackModelException:expectedException];

  // Then
  assertThat(type, is(kMSTypeHandledError));
  assertThat(errorId, notNilValue());
  assertThat(exception, is(expectedException));
}

#pragma mark - Automatic Processing Tests

- (void)testSendOrAwaitWhenAlwaysSendIsTrue {

  // If
  MSCrashes *crashes = OCMPartialMock([MSCrashes new]);
  id<MSLogManager> logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  [crashes setAutomaticProcessing:NO];
  OCMStub([crashes shouldAlwaysSend]).andReturn(YES);
  __block NSUInteger numInvocations = 0;
  [self setProcessLogImplementation:(^(NSInvocation *) {
    numInvocations++;
  }) withLogManager:logManagerMock withCrashes:crashes];
  [self startCrashes:crashes withReports:YES withLogManager:logManagerMock];
  NSMutableArray *reportIds = [self idListFromReports:[crashes unprocessedCrashReports]];

  // When
  BOOL alwaysSendVal = [crashes sendCrashReportsOrAwaitUserConfirmationForFilteredIds:reportIds];

  // Then
  XCTAssertEqual([reportIds count], numInvocations);
  XCTAssertTrue(alwaysSendVal);
}

- (void)testSendOrAwaitWhenAlwaysSendIsFalseAndNotifyAlwaysSend {

  // If
  MSCrashes *crashes = OCMPartialMock([MSCrashes new]);
  id<MSLogManager> logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  [crashes setAutomaticProcessing:NO];
  OCMStub([crashes shouldAlwaysSend]).andReturn(NO);
  __block NSUInteger numInvocations = 0;
  [self setProcessLogImplementation:(^(NSInvocation *) {
    numInvocations++;
  }) withLogManager:logManagerMock withCrashes:crashes];
  [self startCrashes:crashes withReports:YES withLogManager:logManagerMock];
  NSMutableArray *reports = [self idListFromReports:[crashes unprocessedCrashReports]];

  // When
  BOOL alwaysSendVal = [crashes sendCrashReportsOrAwaitUserConfirmationForFilteredIds:reports];

  // Then
  XCTAssertEqual(numInvocations, 0U);
  XCTAssertFalse(alwaysSendVal);

  // When
  [crashes notifyWithUserConfirmation:MSUserConfirmationAlways];

  // Then
  XCTAssertEqual([reports count], numInvocations);
}

- (void)testSendOrAwaitWhenAlwaysSendIsFalseAndNotifySend {

  // If
  MSCrashes *crashes = OCMPartialMock([MSCrashes new]);
  id<MSLogManager> logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  [crashes setAutomaticProcessing:NO];
  OCMStub([crashes shouldAlwaysSend]).andReturn(NO);
  __block NSUInteger numInvocations = 0;
  [self setProcessLogImplementation:(^(NSInvocation *) {
    numInvocations++;
  }) withLogManager:logManagerMock withCrashes:crashes];
  [self startCrashes:crashes withReports:YES withLogManager:logManagerMock];
  NSMutableArray *reportIds = [self idListFromReports:[crashes unprocessedCrashReports]];

  // When
  BOOL alwaysSendVal = [crashes sendCrashReportsOrAwaitUserConfirmationForFilteredIds:reportIds];

  // Then
  XCTAssertEqual(0U, numInvocations);
  XCTAssertFalse(alwaysSendVal);

  // When
  [crashes notifyWithUserConfirmation:MSUserConfirmationSend];

  // Then
  XCTAssertEqual([reportIds count], numInvocations);
}

- (void)testSendOrAwaitWhenAlwaysSendIsFalseAndNotifyDontSend {

  // If
  MSCrashes *crashes = OCMPartialMock([MSCrashes new]);
  id<MSLogManager> logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  [crashes setAutomaticProcessing:NO];
  [crashes applyEnabledState:YES];
  OCMStub([crashes shouldAlwaysSend]).andReturn(NO);
  __block int numInvocations = 0;
  [self setProcessLogImplementation:(^(NSInvocation *) {
    numInvocations++;
  }) withLogManager:logManagerMock withCrashes:crashes];
  NSMutableArray *reportIds = [self idListFromReports:[crashes unprocessedCrashReports]];

  // When
  BOOL alwaysSendVal = [crashes sendCrashReportsOrAwaitUserConfirmationForFilteredIds:reportIds];
  [crashes notifyWithUserConfirmation:MSUserConfirmationDontSend];

  // Then
  XCTAssertFalse(alwaysSendVal);
  XCTAssertEqual(0, numInvocations);
}

- (void)testGetUnprocessedCrashReportsWhenThereAreNone {

  // If
  MSCrashes *crashes = OCMPartialMock([MSCrashes new]);
  id<MSLogManager> logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  [crashes setAutomaticProcessing:NO];
  [self startCrashes:crashes withReports:NO withLogManager:logManagerMock];

  // When
  NSArray<MSErrorReport *> *reports = [crashes unprocessedCrashReports];

  // Then
  XCTAssertEqual([reports count], 0U);
}

- (void)testSendErrorAttachments {

  // If
  MSCrashes *crashes = OCMPartialMock([MSCrashes new]);
  id<MSLogManager> logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  [crashes setAutomaticProcessing:NO];
  MSErrorReport *report = OCMPartialMock([MSErrorReport new]);
  OCMStub([report incidentIdentifier]).andReturn(@"incidentId");
  __block NSUInteger numInvocations = 0;
  __block NSMutableArray<MSErrorAttachmentLog *> *enqueuedAttachments = [[NSMutableArray alloc] init];
  NSMutableArray<MSErrorAttachmentLog *> *attachments = [[NSMutableArray alloc] init];
  [self setProcessLogImplementation:(^(NSInvocation *invocation) {
    numInvocations++;
    MSErrorAttachmentLog *attachmentLog;
    [invocation getArgument:&attachmentLog atIndex:2];
    [enqueuedAttachments addObject:attachmentLog];
  }) withLogManager:logManagerMock withCrashes:crashes];
  [self startCrashes:crashes withReports:NO withLogManager:logManagerMock];

  // When
  [attachments addObject:[[MSErrorAttachmentLog alloc] initWithFilename:@"name" attachmentText:@"text1"]];
  [attachments addObject:[[MSErrorAttachmentLog alloc] initWithFilename:@"name" attachmentText:@"text2"]];
  [attachments addObject:[[MSErrorAttachmentLog alloc] initWithFilename:@"name" attachmentText:@"text3"]];
  [crashes sendErrorAttachments:attachments withIncidentIdentifier:report.incidentIdentifier];

  // Then
  XCTAssertEqual([attachments count], numInvocations);
  for (MSErrorAttachmentLog *log in enqueuedAttachments) {
    XCTAssertTrue([attachments containsObject:log]);
  }
}

- (void)testGetUnprocessedCrashReports {

  // If
  MSCrashes *crashes = OCMPartialMock([MSCrashes new]);
  id<MSLogManager> logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  [crashes setAutomaticProcessing:NO];

  NSArray *reports = [self startCrashes:crashes withReports:YES withLogManager:logManagerMock];

  // When
  NSArray *retrievedReports = [crashes unprocessedCrashReports];

  // Then
  XCTAssertEqual([reports count], [retrievedReports count]);
  for (MSErrorReport* retrievedReport in retrievedReports) {
    BOOL foundReport = NO;
    for (MSErrorReport* report in reports) {
      if ([report.incidentIdentifier isEqualToString:retrievedReport.incidentIdentifier]) {
        foundReport = YES;
        break;
      }
    }
    XCTAssertTrue(foundReport);
  }
}

- (void)testStartingCrashesWithoutAutomaticProcessing {

  // If
  MSCrashes *crashes = OCMPartialMock([MSCrashes new]);
  id<MSLogManager> logManagerMock = OCMProtocolMock(@protocol(MSLogManager));
  [crashes setAutomaticProcessing:NO];
  NSArray *reports = [self startCrashes:crashes withReports:YES withLogManager:logManagerMock];

  // When
  NSArray *retrievedReports = [crashes unprocessedCrashReports];

  // Then
  XCTAssertEqual([reports count], [retrievedReports count]);
  for (MSErrorReport* retrievedReport in retrievedReports) {
    BOOL foundReport = NO;
    for (MSErrorReport* report in reports) {
      if ([report.incidentIdentifier isEqualToString:retrievedReport.incidentIdentifier]) {
        foundReport = YES;
        break;
      }
    }
    XCTAssertTrue(foundReport);
  }
}

#pragma mark Helper

/**
 * Start Crashes (self.sut) with zero or one crash files on disk.
 */
- (NSMutableArray<MSErrorReport *> *)startCrashes:(MSCrashes*)crashes withReports:(BOOL)startWithReports withLogManager:(id<MSLogManager>)logManager {
  NSMutableArray<MSErrorReport *> *reports = [NSMutableArray<MSErrorReport*> new];
  if (startWithReports) {
    for (NSString* fileName in @[@"live_report_exception"]) {
      XCTAssertTrue([MSCrashesTestUtil copyFixtureCrashReportWithFileName:fileName]);
      NSData *data = [MSCrashesTestUtil dataOfFixtureCrashReportWithFileName:fileName];
      NSError *error;
      MSPLCrashReport *report = [[MSPLCrashReport alloc] initWithData:data error:&error];
      [reports addObject:[MSErrorLogFormatter errorReportFromCrashReport:report]];
    }
  }
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [crashes startWithLogManager:logManager appSecret:kMSTestAppSecret];
  });

  if (startWithReports) {
    assertThat(crashes.crashFiles, hasCountOf(1));
  }
  return reports;
}

/**
 * Attaches the given block to the given logManager's "processLog" method when invoked with Crash's groupId.
 */
- (void)setProcessLogImplementation:(void (^)(NSInvocation *))invocation withLogManager:(id<MSLogManager>)logManager withCrashes:(MSCrashes*)crashes {
  id<MSCrashesDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashesDelegate));
  NSString *groupId = [crashes groupId];
  OCMStub([logManager processLog:OCMOCK_ANY forGroupId:groupId]).andDo(invocation);
  [crashes setDelegate:delegateMock];
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
    log.timestamp = [NSDate dateWithTimeIntervalSince1970:42];
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

- (NSMutableArray *)idListFromReports:(NSArray *)reports {
  NSMutableArray *ids = [NSMutableArray new];
  for (MSErrorReport *report in reports) {
    [ids addObject:report.incidentIdentifier];
  }
  return ids;
}

@end

