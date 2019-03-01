#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextDelegate.h"
#import "MSTestFrameworks.h"

@interface MSAuthTokenContext ()

+ (void)resetSharedInstance;

@end

@interface MSAuthTokenContextTests : XCTestCase

@property(nonatomic) MSAuthTokenContext *sut;

@end

@implementation MSAuthTokenContextTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSAuthTokenContext sharedInstance];
}

- (void)tearDown {
  [MSAuthTokenContext resetSharedInstance];
  [super tearDown];
}

#pragma mark - Tests

- (void)testSetAuthToken {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSString *expectedAccountId = @"account1";
  NSString *expectedAccountId2 = @"account2";
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId];

  // Then
  XCTAssertEqualObjects([self.sut authToken], expectedAuthToken);
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateUserWithAuthToken:expectedAuthToken]);

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut didReceiveAuthToken:expectedAuthToken]);

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId2];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateUserWithAuthToken:expectedAuthToken]);
}

- (void)testClearAuthToken {

  // If
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:@"some-token" withAccountId:@"some-id"];
  [self.sut clearAuthToken];

  // Then
  XCTAssertNil([self.sut authToken]);
  OCMVerify([delegateMock authTokenContext:self.sut didReceiveAuthToken:nil]);
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateUserWithAuthToken:nil]);
}

- (void)testRemoveDelegate {

  // If
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // Then
  OCMReject([delegateMock authTokenContext:self.sut didReceiveAuthToken:OCMOCK_ANY]);

  // When
  [self.sut removeDelegate:delegateMock];
  [self.sut setAuthToken:@"something" withAccountId:@"someome"];
}

@end
