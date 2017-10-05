#import "MSCrashHandlerSetupDelegate.h"
#import "MSTestFrameworks.h"
#import "MSWrapperCrashesHelper.h"
#import "MSCrashesTestUtil.h"
#import "MSErrorAttachmentLog.h"
#import "MSChannelDefault.h"
#import "MSLogManagerDefault.h"
#import "MSCrashesInternal.h"
#import "MSCrashesPrivate.h"
#import "MSCrashesDelegate.h"
#import "MSUtility.h"
#import "MSUserDefaults.h"
#import "MSErrorLogFormatter.h"
#import "MSCrashReporter.h"
#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"

@interface MSWrapperCrashesHelperTests : XCTestCase

@property MSLogManagerDefault* logManager;

@end

@interface MSCrashes ()

- (void)startCrashProcessing;

@end

@implementation MSWrapperCrashesHelperTests

static NSString* const kMSTestAppSecret = @"app secret";

-(void)setUp {
  self.logManager = OCMClassMock([MSLogManagerDefault class]);
}

- (void)tearDown {
  [super tearDown];
  [[MSCrashes sharedInstance] deleteAllFromCrashesDirectory];
  [MSCrashesTestUtil deleteAllFilesInDirectory:[[MSCrashes sharedInstance].logBufferDir path]];
  [MSCrashes setEnabled:NO];
  [MSCrashes setEnabled:YES];
}
#pragma mark - General Tests

- (void)testSettingAndGettingDelegateWorks {
  id<MSCrashHandlerSetupDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashHandlerSetupDelegate));
  [MSWrapperCrashesHelper setCrashHandlerSetupDelegate:delegateMock];
  id<MSCrashHandlerSetupDelegate> retrievedDelegate = [MSWrapperCrashesHelper getCrashHandlerSetupDelegate];
  assertThat(delegateMock, equalTo(retrievedDelegate));
}

#pragma mark - Automatic Processing Tests

- (void)testSendOrAwaitWhenAlwaysSendIsTrue {

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:NO];
  [self setAlwaysSendWithValue:YES];
  __block NSUInteger numInvocations = 0;
  [self setProcessLogImplementation:(^(NSInvocation *) {
    numInvocations++;
  })];
 [self startCrashesWithReports:YES];
  
  NSMutableArray<MSErrorReport*> *reports = [NSMutableArray arrayWithArray:[MSWrapperCrashesHelper getUnprocessedCrashReports]];
//  [reports removeObjectAtIndex:0];
//  [reports removeObjectAtIndex:0];

  // When
  [MSWrapperCrashesHelper sendCrashReportsOrAwaitUserConfirmationForFilteredList:reports];

  // Then
  XCTAssertEqual([reports count], numInvocations);
}

- (void)testSendOrAwaitWhenAlwaysSendIsFalseAndNotifyAlwaysSend {

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:NO];
  [self setAlwaysSendWithValue:NO];
  __block NSUInteger numInvocations = 0;
  [self setProcessLogImplementation:(^(NSInvocation *) {
    numInvocations++;
  })];
//  [reports removeObjectAtIndex:0];
//  [reports removeObjectAtIndex:0];
  [self startCrashesWithReports:YES];
  NSMutableArray<MSErrorReport*> *reports = [NSMutableArray arrayWithArray:[MSWrapperCrashesHelper getUnprocessedCrashReports]];

  // When
  [MSWrapperCrashesHelper sendCrashReportsOrAwaitUserConfirmationForFilteredList:reports];

  // Then
  XCTAssertEqual(numInvocations, 0U);

  // When
  [MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];

  // Then
  XCTAssertEqual([reports count], numInvocations);
}

- (void)testSendOrAwaitWhenAlwaysSendIsFalseAndNotifySend {

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:NO];
  [self setAlwaysSendWithValue:NO];
  __block NSUInteger numInvocations = 0;
  [self setProcessLogImplementation:(^(NSInvocation *) {
    numInvocations++;
  })];
  [self startCrashesWithReports:YES];
//  [reports removeObjectAtIndex:0];
//  [reports removeObjectAtIndex:0];
  NSMutableArray<MSErrorReport*> *reports = [NSMutableArray arrayWithArray:[MSWrapperCrashesHelper getUnprocessedCrashReports]];

  // When
  [MSWrapperCrashesHelper sendCrashReportsOrAwaitUserConfirmationForFilteredList:reports];

  // Then
  XCTAssertEqual(0U, numInvocations);

  // When
  [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];

  // Then
  XCTAssertEqual([reports count], numInvocations);
}

- (void)testSendOrAwaitWhenAlwaysSendIsFalseAndNotifyDontSend {

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:NO];
  [self setAlwaysSendWithValue:NO];
  __block int numInvocations = 0;
  NSMutableArray<MSErrorReport *> *reports = [self startCrashesWithReports:YES];

  [self setProcessLogImplementation:(^(NSInvocation *) {
    numInvocations++;
  })];
//  [reports removeObjectAtIndex:0];
//  [reports removeObjectAtIndex:0];

  // When
  [MSWrapperCrashesHelper sendCrashReportsOrAwaitUserConfirmationForFilteredList:reports];
  [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];

  // Then
  XCTAssertEqual(0, numInvocations);
}

- (void)testGetUnprocessedCrashReportsWhenThereAreNone {

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:false];
  [self startCrashesWithReports:NO];

  // When
  NSArray<MSErrorReport *> *reports = [MSWrapperCrashesHelper getUnprocessedCrashReports];

  // Then
  XCTAssertEqual([reports count], 0U);
}

- (void)testSendErrorAttachments {

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:NO];
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
  })];
  [self startCrashesWithReports:NO];

  // When
  [attachments addObject:[[MSErrorAttachmentLog alloc] initWithFilename:@"name" attachmentText:@"text1"]];
  [attachments addObject:[[MSErrorAttachmentLog alloc] initWithFilename:@"name" attachmentText:@"text2"]];
  [attachments addObject:[[MSErrorAttachmentLog alloc] initWithFilename:@"name" attachmentText:@"text3"]];
  [MSWrapperCrashesHelper sendErrorAttachments:attachments forErrorReport:report];

  // Then
  XCTAssertEqual([attachments count], numInvocations);
  for (MSErrorAttachmentLog *log in enqueuedAttachments) {
    XCTAssertTrue([attachments containsObject:log]);
  }
}

- (void)testGetUnprocessedCrashReports {
  //TODO: verify that callbacks aren't invoked?

  // If
  [MSWrapperCrashesHelper setAutomaticProcessing:NO];
  NSArray *reports = [self startCrashesWithReports:YES];

  // When
  NSArray *retrievedReports = [MSWrapperCrashesHelper getUnprocessedCrashReports];

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

- (NSMutableArray<MSErrorReport *> *)startCrashesWithReports:(BOOL)startWithReports {
  NSMutableArray<MSErrorReport *> *reports = [NSMutableArray<MSErrorReport*> new];
  [[MSCrashes sharedInstance] deleteAllFromCrashesDirectory];
  if (startWithReports) {
    for (NSString* fileName in @[@"live_report_exception"]) {
      XCTAssertTrue([MSCrashesTestUtil copyFixtureCrashReportWithFileName:fileName]);
      NSData *data = [MSCrashesTestUtil dataOfFixtureCrashReportWithFileName:fileName];
      NSError *error;
      MSPLCrashReport *report = [[MSPLCrashReport alloc] initWithData:data error:&error];
      [reports addObject:[MSErrorLogFormatter errorReportFromCrashReport:report]];
    }
  }
  [[MSCrashes sharedInstance] startWithLogManager:self.logManager appSecret:kMSTestAppSecret];
  if (startWithReports) {
    assertThat([MSCrashes sharedInstance].crashFiles, hasCountOf(1));
  }
  return reports;
}

// TODO: refactor these into utility if they can also be used by MSCrashesTests.
- (void)setAlwaysSendWithValue:(BOOL)value {
  [MS_USER_DEFAULTS setObject:[NSNumber numberWithBool:value] forKey:@"MSUserConfirmation"];
}

- (void)setProcessLogImplementation:(void (^)(NSInvocation *))invocation {
  id<MSCrashesDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashesDelegate));
  NSString *groupId = [[MSCrashes sharedInstance] groupId];
  OCMStub([self.logManager processLog:OCMOCK_ANY forGroupId:groupId]).andDo(invocation);
  [MSCrashes setDelegate:delegateMock];
}

@end
