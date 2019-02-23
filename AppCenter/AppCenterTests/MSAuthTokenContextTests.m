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
  NSString *expectedAccountId1 = @"account2";
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId];

  // Then
  XCTAssertEqualObjects([self.sut getAuthToken], expectedAuthToken);
  OCMVerify([delegateMock authTokenContext:self.sut didReceiveAuthToken:expectedAuthToken forNewUser:YES]);
  
  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId];
  
  //Then
  OCMVerify([delegateMock authTokenContext:self.sut didReceiveAuthToken:expectedAuthToken forNewUser:NO]);
  
  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId1];
  
  //Then
  OCMVerify([delegateMock authTokenContext:self.sut didReceiveAuthToken:expectedAuthToken forNewUser:YES]);
}

- (void)testClearAuthToken {
  
  // If
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];
  
  // When
  [self.sut clearAuthToken];
  
  // Then
  XCTAssertNil([self.sut getAuthToken]);
  OCMVerify([delegateMock authTokenContext:self.sut didReceiveAuthToken:nil forNewUser:YES]);
}

- (void)testRemoveDelegate {

  // If
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // Then
  OCMReject([delegateMock authTokenContext:self.sut didReceiveAuthToken:OCMOCK_ANY forNewUser:OCMOCK_ANY]);

  // When
  [self.sut removeDelegate:delegateMock];
  [self.sut setAuthToken:@"something" withAccountId:@"someome"];
}

@end
