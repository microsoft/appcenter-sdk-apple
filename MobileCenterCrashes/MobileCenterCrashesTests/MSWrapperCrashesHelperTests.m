#import "MSCrashHandlerSetupDelegate.h"
#import "MSTestFrameworks.h"
#import "MSWrapperCrashesHelper.h"
#import "MSCrashesInternal.h"


@interface MSWrapperCrashesHelperTests : XCTestCase
@end

@implementation MSWrapperCrashesHelperTests

- (void)testSettingAndGettingDelegateWorks {
  
  // If
  id<MSCrashHandlerSetupDelegate> delegateMock = OCMProtocolMock(@protocol(MSCrashHandlerSetupDelegate));
  [MSWrapperCrashesHelper setCrashHandlerSetupDelegate:delegateMock];
  
  // When
  id<MSCrashHandlerSetupDelegate> retrievedDelegate = [MSWrapperCrashesHelper getCrashHandlerSetupDelegate];
  
  // Then
  assertThat(delegateMock, equalTo(retrievedDelegate));
}

- (void)testSetAutomaticProcessing {
  
  // If
  MSCrashes *crashesMock = [self getSharedCrashesMock];
  
  // When
  [MSWrapperCrashesHelper setAutomaticProcessing:YES];
  
  // Then
  OCMVerify([crashesMock setAutomaticProcessing:YES]);
  
  // When
  [MSWrapperCrashesHelper setAutomaticProcessing:NO];
  
  // Then
  OCMVerify([crashesMock setAutomaticProcessing:NO]);
}

- (void)testGetUnprocessedCrashReports {
  
  // If
  MSCrashes *crashesMock = [self getSharedCrashesMock];
  NSArray *unprocessedReports = @[];
  OCMStub([crashesMock getUnprocessedCrashReports]).andReturn(unprocessedReports);
  
  // When
  NSArray *retrievedReports = [MSWrapperCrashesHelper getUnprocessedCrashReports];
  
  // Then
  OCMVerify([crashesMock getUnprocessedCrashReports]);
  XCTAssertEqual(unprocessedReports, retrievedReports);
}

- (void)testSendCrashReportsOrAwaitUserConfirmationForFilteredList {
  
  // If
  MSCrashes *crashesMock = [self getSharedCrashesMock];
  NSArray *filteredList = @[];
  
  // When
  [MSWrapperCrashesHelper sendCrashReportsOrAwaitUserConfirmationForFilteredList:filteredList];
  
  // Then
  OCMVerify([crashesMock sendCrashReportsOrAwaitUserConfirmationForFilteredList:filteredList]);
}

- (void)testsendErrorAttachmentsWithIncidentIdentifier {
  
  // If
  MSCrashes *crashesMock = [self getSharedCrashesMock];
  NSArray *errorAttachments = @[];
  NSString *incidentId = @"incident id";
  
  // When
  [MSWrapperCrashesHelper sendErrorAttachments:errorAttachments withIncidentIdentifier:incidentId];
  
  // Then
  OCMVerify([crashesMock sendErrorAttachments:errorAttachments withIncidentIdentifier:incidentId]);
}

#pragma mark Helpers

- (MSCrashes*)getSharedCrashesMock {
  MSCrashes *crashesMock = OCMPartialMock([MSCrashes new]);
  id crashesClassMock = OCMClassMock([MSCrashes class]);
  OCMStub(ClassMethod([crashesClassMock sharedInstance])).andReturn(crashesMock);
  return crashesMock;
}

@end
