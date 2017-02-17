#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MSServiceAbstract.h"
#import "MSServiceInternal.h"
#import "MSUpdatesInternal.h"

@interface MSUpdatesTests : XCTestCase

@property(nonatomic, strong) MSUpdates *sut;

@end

@implementation MSUpdatesTests

- (void)setUp {
  [super setUp];

  self.sut = [MSUpdates new];
}

- (void)testSetApiUrlWorks {

  // When
  NSString *testUrl = @"https://example.com";
  [self.sut setApiUrl:testUrl];

  // Then
  XCTAssertTrue([[self.sut apiUrl] isEqualToString:testUrl]);
}

- (void)testSetInstallUrlWorks {

  // When
  NSString *testUrl = @"https://example.com";
  [self.sut setInstallUrl:testUrl];

  // Then
  XCTAssertTrue([[self.sut installUrl] isEqualToString:testUrl]);
}

- (void)testDefaultInstallUrlWorks {

  // Then
  XCTAssertNotNil([self.sut installUrl]);
  XCTAssertTrue([[self.sut installUrl] isEqualToString:@"http://install.asgard-int.trafficmanager.net"]);
}

- (void)testDefaultApiUrlWorks {

  // Then
  XCTAssertNotNil([self.sut apiUrl]);
  XCTAssertTrue([[self.sut apiUrl] isEqualToString:@"https://asgard-int.trafficmanager.net/api/v0.1"]);
}

- (void)testHandleUpdate {

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];
  id updatesMock = OCMPartialMock(self.sut);
  OCMStub([updatesMock showConfirmationAlert:[OCMArg any]])
      .andDo(^(NSInvocation *invocation){
      });

  // When
  [updatesMock handleUpdate:details];

  // Then
  OCMReject([updatesMock showConfirmationAlert:[OCMArg any]]);

  // If
  details.id = @"valid-id";
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com/valid/url"];

  // When
  [updatesMock handleUpdate:details];

  // Then
  OCMReject([updatesMock showConfirmationAlert:[OCMArg any]]);

  // If
  details.status = @"available";
  details.minOs = @"1000.0";

  // When
  [updatesMock handleUpdate:details];

  // Then
  OCMReject([updatesMock showConfirmationAlert:[OCMArg any]]);

  // If
  details.minOs = @"1.0";
  OCMStub([updatesMock isNewerVersion:[OCMArg any]]).andReturn(NO);

  // When
  [updatesMock handleUpdate:details];

  // Then
  OCMReject([updatesMock showConfirmationAlert:[OCMArg any]]);

  // If
  OCMStub([updatesMock isNewerVersion:[OCMArg any]]).andReturn(YES);

  // When
  [updatesMock handleUpdate:details];

  // Then
  OCMVerify([updatesMock showConfirmationAlert:[OCMArg any]]);
}

@end
